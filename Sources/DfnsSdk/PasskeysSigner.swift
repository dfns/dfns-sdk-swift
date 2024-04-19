import Foundation

public enum PasskeysSignerError: Error {
    // Throw in all other cases
    case unexpected(code: String?, message: String?, error: String?)
}

/**
 Wrapper class for the Passkey class imported from the `react-native-passkey library`
 Converts completion handlers into async functions and make the necessary conversion to work with Dfns API
 */
public final class PasskeysSigner {
    private var passkey = Passkey()

    public init() {}

    public func register(challenge: DfnsApi.UserRegistrationChallenge) async throws -> DfnsApi.Fido2Attestation {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            let result = await withCheckedContinuation { continuation in
                register(challenge: challenge) { fido2Attestation, exception in
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

    private func register(challenge: DfnsApi.UserRegistrationChallenge, completion: @escaping (DfnsApi.Fido2Attestation?, PasskeysSignerError?) -> Void) {
        let userId = challenge.user.id
        let displayName = challenge.user.displayName
        let relyingParty = challenge.rp.id
        let challenge = Utils.base64URLUnescaped(challenge.challenge)

        passkey.register(relyingParty, challenge: challenge, displayName: displayName, userId: userId, securityKey: false,
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

    private func sign(challenge: DfnsApi.UserActionChallenge, completion: @escaping (DfnsApi.Fido2Assertion?, PasskeysSignerError?) -> Void) {
        let relyingParty = challenge.rp.id
        let challenge = Utils.base64URLUnescaped(challenge.challenge)

        passkey.authenticate(relyingParty, challenge: challenge, securityKey: false, resolve: { authResult in
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
