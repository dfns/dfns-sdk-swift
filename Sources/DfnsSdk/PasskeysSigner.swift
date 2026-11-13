import Foundation

public enum PasskeysSignerError: Error {
    // Throw in all other cases
    case unexpected(code: String?, message: String?, error: String?)
    case relyingPartyNotWhitelisted(message: String?)
}

/**
 Wrapper class for the Passkey class imported from the `react-native-passkey library`
 Converts completion handlers into async functions and make the necessary conversion to work with Dfns API
 */
public final class PasskeysSigner: Sendable {
    private let passkey = Passkey()

    /// Default timeout (ms) for credential operations, matching the other DFNS frontend SDKs.
    /// Note: iOS `AuthenticationServices` does not expose a timeout for passkey requests, so on iOS
    /// this value is accepted for API parity but is not applied by the platform (same behaviour as
    /// the DFNS React Native SDK on iOS).
    public static let defaultWaitTimeout = 60000

    /**
     The relying party identifies your application to users, when users create/use passkeys. (Read more [here](https://www.w3.org/TR/webauthn-2/#relying-party)).
     - id: a valid domain string identifying the WebAuthn Relying Party. In other words, its the domain your application is running on, which will be tied to the passkeys that users create.
     We advise to use the root domain, not the full domain (eg `acme.com`, not `app.acme.com` nor `foo.app.acme.com`), that way, passkeys created
     by your users can be re-used on other subdomains (eg. on `foo.acme.com` and `bar.acme.com`) in the future. Read more [here](https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#rp).
     - name: a string representing the name of the relying party (e.g. "Acme"). This is the name the user may be presented with when creating or validating a passkey.
     */
    private let relyingParty: DfnsApi.RelyingParty
    private let timeout: Int

    public init(relyingParty: DfnsApi.RelyingParty, timeout: Int = PasskeysSigner.defaultWaitTimeout) throws {
        guard !relyingParty.id.isEmpty, !relyingParty.name.isEmpty else {
            throw PasskeysSignerError.unexpected(code: nil, message: "Relying party ID and name must be specified", error: nil)
        }
        self.relyingParty = relyingParty
        self.timeout = timeout
    }

    public func create(challenge: DfnsApi.UserRegistrationChallenge) async throws -> DfnsApi.Fido2Attestation {
        try await register(challenge: challenge)
    }

    // AuthenticationServices must be driven from the main thread, so the passkey request runs on the main actor.
    @MainActor
    private func register(challenge: DfnsApi.UserRegistrationChallenge) async throws -> DfnsApi.Fido2Attestation {
        let userId = challenge.user.id
        let displayName = challenge.user.displayName
        let challengeBase64url = Utils.base64URLUnescaped(challenge.challenge)

        return try await withCheckedThrowingContinuation { continuation in
            passkey.register(self.relyingParty.id, challenge: challengeBase64url, displayName: displayName, userId: userId, securityKey: false,
                             resolve: { authResult in
                                 do {
                                     guard let attestationData = try self.extractFromAuthResultValue(authResult, path: ["response", "rawAttestationObject"]),
                                           let clientData = try self.extractFromAuthResultValue(authResult, path: ["response", "rawClientDataJSON"]),
                                           let credId = try self.extractFromAuthResultValue(authResult, path: ["credentialID"]) else {
                                         throw PasskeysSignerError.unexpected(code: nil, message: "Passkey response is missing a required field", error: nil)
                                     }
                                     let credentialInfo = DfnsApi.Fido2AttestationData(
                                         attestationData: attestationData,
                                         clientData: clientData,
                                         credId: credId
                                     )
                                     let fido2Attestation = DfnsApi.Fido2Attestation(credentialInfo: credentialInfo, credentialKind: "Fido2")
                                     continuation.resume(returning: fido2Attestation)
                                 } catch {
                                     continuation.resume(throwing: error)
                                 }
                             }, reject: { code, message, error in
                                 continuation.resume(throwing: PasskeysSignerError.unexpected(code: code, message: message, error: error))
                             })
        }
    }

    public func sign(challenge: DfnsApi.UserActionChallenge) async throws -> DfnsApi.Fido2Assertion {
        try await authenticate(challenge: challenge)
    }

    // AuthenticationServices must be driven from the main thread, so the passkey request runs on the main actor.
    @MainActor
    private func authenticate(challenge: DfnsApi.UserActionChallenge) async throws -> DfnsApi.Fido2Assertion {
        let challengeBase64url = Utils.base64URLUnescaped(challenge.challenge)
        let allowedCredentials = try PasskeysSigner.allowedCredentialIds(challenge)

        return try await withCheckedThrowingContinuation { continuation in
            passkey.authenticate(self.relyingParty.id, challenge: challengeBase64url, securityKey: false, allowedCredentials: allowedCredentials, resolve: { authResult in
                do {
                    guard let clientData = try self.extractFromAuthResultValue(authResult, path: ["response", "rawClientDataJSON"]),
                          let credId = try self.extractFromAuthResultValue(authResult, path: ["credentialID"]),
                          let signature = try self.extractFromAuthResultValue(authResult, path: ["response", "signature"]),
                          let authenticatorData = try self.extractFromAuthResultValue(authResult, path: ["response", "rawAuthenticatorData"]) else {
                        throw PasskeysSignerError.unexpected(code: nil, message: "Passkey response is missing a required field", error: nil)
                    }
                    let credentialAssertion = DfnsApi.Fido2AssertionData(
                        clientData: clientData,
                        credId: credId,
                        signature: signature,
                        authenticatorData: authenticatorData,
                        userHandle: PasskeysSigner.userHandle(from: authResult)
                    )
                    let fido2Assertion = DfnsApi.Fido2Assertion(kind: "Fido2", credentialAssertion: credentialAssertion)
                    continuation.resume(returning: fido2Assertion)
                } catch {
                    continuation.resume(throwing: error)
                }
            }, reject: { code, message, error in
                continuation.resume(throwing: PasskeysSignerError.unexpected(code: code, message: message, error: error))
            })
        }
    }

    /// WebAuthn credential ids from `allowCredentials.webauthn`.
    /// Key ids stay out: they belong to the key signer, not this passkey request.
    /// An empty list leaves the request unrestricted. A non-empty list that decodes
    /// to nothing throws, because an empty platform list would allow any passkey.
    static func allowedCredentialIds(_ challenge: DfnsApi.UserActionChallenge) throws -> [Data] {
        let descriptors = challenge.allowCredentials.webauthn
        let ids = descriptors.compactMap { Data(base64Encoded: Utils.base64URLUnescaped($0.id)) }
        if !descriptors.isEmpty && ids.isEmpty {
            throw PasskeysSignerError.unexpected(code: nil, message: "Allow list did not decode to any credential id", error: nil)
        }
        return ids
    }

    /// User handle for an assertion. Nil when `userID` is missing or empty.
    static func userHandle(from authResult: NSDictionary) -> String? {
        guard let userID = authResult["userID"] as? String, !userID.isEmpty else {
            return nil
        }
        guard let encoded = userID.data(using: .utf8)?.base64EncodedString() else {
            return nil
        }
        return Utils.base64URLEscape(encoded)
    }

    func extractFromAuthResultValue(_ authResult: NSDictionary, path: [String]) throws -> String? {
        guard let key = path.first else {
            throw PasskeysSignerError.unexpected(code: nil, message: "Passkey response path is empty", error: nil)
        }
        let value = authResult[key]
        let rest = Array(path.dropFirst())
        if rest.isEmpty {
            if value == nil || value is NSNull {
                return nil
            }
            guard let string = value as? String else {
                throw PasskeysSignerError.unexpected(code: nil, message: "Passkey response value at \(key) has an unexpected type", error: nil)
            }
            return Utils.base64URLEscape(string)
        }
        if value == nil || value is NSNull {
            return nil
        }
        guard let nested = value as? NSDictionary else {
            throw PasskeysSignerError.unexpected(code: nil, message: "Passkey response value at \(key) has an unexpected type", error: nil)
        }
        return try extractFromAuthResultValue(nested, path: rest)
    }
}
