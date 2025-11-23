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
@MainActor
public final class PasskeysSigner {
	private let passkey = Passkey()
	
	/**
	 The relying party ID identifies your application to users, when users create/use passkeys. (Read more [here](https://www.w3.org/TR/webauthn-2/#relying-party)).
	 It is a valid domain string identifying the WebAuthn Relying Party. In other words, its the domain your application is running on, which will be tied to the passkeys that users create.
	 We advise to use the root domain, not the full domain (eg `acme.com`, not `app.acme.com` nor `foo.app.acme.com`), that way, passkeys created
	 by your users can be re-used on other subdomains (eg. on `foo.acme.com` and `bar.acme.com`) in the future. Read more [here](https://developer.mozilla.org/en-US/docs/Web/API/PublicKeyCredentialCreationOptions#rp).
	 */
	private let relyingPartyId: String
	
	public init(relyingPartyId: String) {
		self.relyingPartyId = relyingPartyId
	}
	
	public func register(challenge: DfnsApi.UserRegistrationChallenge) async throws -> DfnsApi.Fido2Attestation {
		try await withCheckedThrowingContinuation { continuation in
			register(challenge: challenge) { result in
				continuation.resume(with: result)
			}
		}
	}
	
	private func register(
		challenge: DfnsApi.UserRegistrationChallenge,
		completion: @escaping (Result<DfnsApi.Fido2Attestation, Error>) -> Void
	) {
		let userId = challenge.user.id
		let displayName = challenge.user.displayName
		let challengeBase64url = Utils.base64URLUnescaped(challenge.challenge)
		
		passkey.register(
			self.relyingPartyId,
			challenge: challengeBase64url,
			displayName: displayName,
			userId: userId,
			securityKey: false,
			resolve: { authResult in
				let credentialInfo = DfnsApi.Fido2AttestationData(
					attestationData: self.extractFromAuthResultValue(authResult, path: ["response", "rawAttestationObject"]),
					clientData: self.extractFromAuthResultValue(authResult, path: ["response", "rawClientDataJSON"]),
					credId: self.extractFromAuthResultValue(authResult, path: ["credentialID"])
				)
				let fido2Attestation = DfnsApi.Fido2Attestation(credentialInfo: credentialInfo, credentialKind: "Fido2")
				completion(.success(fido2Attestation))
			},
			reject: { code, message, error in
				let exception = PasskeysSignerError.unexpected(code: code, message: message, error: error)
				completion(.failure(exception))
			}
		)
	}
	
	public func sign(challenge: DfnsApi.UserActionChallenge) async throws -> DfnsApi.Fido2Assertion {
		try await withCheckedThrowingContinuation { continuation in
			sign(challenge: challenge) { result in
				continuation.resume(with: result)
			}
		}
	}
	
	private func sign(
		challenge: DfnsApi.UserActionChallenge,
		completion: @escaping (Result<DfnsApi.Fido2Assertion, Error>) -> Void
	) {
		let challengeBase64url = Utils.base64URLUnescaped(challenge.challenge)
		
		passkey.authenticate(self.relyingPartyId, challenge: challengeBase64url, securityKey: false, resolve: { authResult in
			let credentialAssertion = DfnsApi.Fido2AssertionData(
				clientData: self.extractFromAuthResultValue(authResult, path: ["response", "rawClientDataJSON"]),
				credId: self.extractFromAuthResultValue(authResult, path: ["credentialID"]),
				signature: self.extractFromAuthResultValue(authResult, path: ["response", "signature"]),
				authenticatorData: self.extractFromAuthResultValue(authResult, path: ["response", "rawAuthenticatorData"]),
				userHandle: Utils.base64URLEscape((authResult["userID"] as! String).data(using: .utf8)!.base64EncodedString())
			)
			
			let fido2Assertion = DfnsApi.Fido2Assertion(kind: "Fido2", credentialAssertion: credentialAssertion)
			
			completion(.success(fido2Assertion))
		}, reject: { code, message, error in
			let exception = PasskeysSignerError.unexpected(code: code, message: message, error: error)
			completion(.failure(exception))
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
