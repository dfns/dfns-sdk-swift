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
public final class PasskeysSigner {
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
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            let result = await withCheckedContinuation { continuation in
                create(challenge: challenge) { fido2Attestation, exception in
                    continuation.resume(returning: (fido2Attestation: fido2Attestation, exception: exception))
                }
            }

            if result.exception != nil {
                throw result.exception!
            }

            return result.fido2Attestation!
        } else {
            throw PasskeysSignerError.unexpected(code: PassKeyError.notSupported.rawValue, message: PassKeyError.notSupported.rawValue, error: nil)
        }
    }

    private func create(challenge: DfnsApi.UserRegistrationChallenge, completion: @escaping (DfnsApi.Fido2Attestation?, Error?) -> Void) {
        let userId = challenge.user.id
        let displayName = challenge.user.displayName
        let challengeBase64url = Utils.base64URLUnescaped(challenge.challenge)

        passkey.register(self.relyingParty.id, challenge: challengeBase64url, displayName: displayName, userId: userId, securityKey: false,
                         resolve: { authResult in
                             let credentialInfo = DfnsApi.Fido2AttestationData(
                                 attestationData: self.extractFromAuthResultValue(authResult, path: ["response", "rawAttestationObject"]),
                                 clientData: self.extractFromAuthResultValue(authResult, path: ["response", "rawClientDataJSON"]),
                                 credId: self.extractFromAuthResultValue(authResult, path: ["credentialID"])
                             )
                             let fido2Attestation = DfnsApi.Fido2Attestation(credentialInfo: credentialInfo, credentialKind: "Fido2")
                             completion(fido2Attestation, nil)
                         }, reject: { code, message, error in
                             let exception = PasskeysSignerError.unexpected(code: code, message: message, error: error)
                             completion(nil, exception)
                         })
    }

    public func sign(challenge: DfnsApi.UserActionChallenge) async throws -> DfnsApi.Fido2Assertion {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            let result = await withCheckedContinuation { continuation in
                sign(challenge: challenge) { fido2Assertion, exception in
                    continuation.resume(returning: (fido2Assertion: fido2Assertion, exception: exception))
                }
            }

            if result.exception != nil {
                throw result.exception!
            }

            return result.fido2Assertion!
        } else {
            throw PasskeysSignerError.unexpected(code: PassKeyError.notSupported.rawValue, message: PassKeyError.notSupported.rawValue, error: nil)
        }
    }

    private func sign(challenge: DfnsApi.UserActionChallenge, completion: @escaping (DfnsApi.Fido2Assertion?, Error?) -> Void) {
        let challengeBase64url = Utils.base64URLUnescaped(challenge.challenge)

        passkey.authenticate(self.relyingParty.id, challenge: challengeBase64url, securityKey: false, resolve: { authResult in
            let credentialAssertion = DfnsApi.Fido2AssertionData(
                clientData: self.extractFromAuthResultValue(authResult, path: ["response", "rawClientDataJSON"]),
                credId: self.extractFromAuthResultValue(authResult, path: ["credentialID"]),
                signature: self.extractFromAuthResultValue(authResult, path: ["response", "signature"]),
                authenticatorData: self.extractFromAuthResultValue(authResult, path: ["response", "rawAuthenticatorData"]),
                userHandle: Utils.base64URLEscape((authResult["userID"] as! String).data(using: .utf8)!.base64EncodedString())
            )

            let fido2Assertion = DfnsApi.Fido2Assertion(kind: "Fido2", credentialAssertion: credentialAssertion)

            completion(fido2Assertion, nil)
        }, reject: { code, message, error in
            let exception = PasskeysSignerError.unexpected(code: code, message: message, error: error)
            completion(nil, exception)
        })
    }

    private func extractFromAuthResultValue(_ authResult: NSDictionary, path: [String]) -> String {
        var path = path
        if path.count == 1 {
            return Utils.base64URLEscape(authResult[path.removeFirst()] as! String)
        } else {
            return extractFromAuthResultValue(authResult[path.removeFirst()] as! NSDictionary, path: path)
        }
    }
}
