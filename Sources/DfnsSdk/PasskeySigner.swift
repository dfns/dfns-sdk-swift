import Foundation

public enum PasskeySignerError: Error {
    // Throw in all other cases
    case unexpected(code: String?, message: String?, error: String?)
}


/**
    Wrapper class for the Passkey class imported from the `react-native-passkey library`
    Converts completion handlers into async functions and make the necessary conversion to work with Dfns API
 */
public final class PasskeySigner{
    private var passkey = Passkey()
    private var appOrigin: String
    private var credId: String?
    private var relyingParty: String
    
    public init(appOrigin: String, relyingParty: String){
        self.appOrigin = appOrigin
        self.relyingParty = relyingParty
    }
    
    public func register(challenge: String, displayName: String, userId: String) async throws -> DfnsApi.CredentialInfo {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            let challenge = Utils.base64URLUnescaped(challenge)
            let result = await withCheckedContinuation { continuation in
                register(challenge: challenge, displayName: displayName, userId: userId) { (credentialInfo, exception) in
                    continuation.resume(returning: (credentialInfo: credentialInfo, exception: exception))
                }
            }
            
            if(result.exception != nil){
                throw result.exception!
            }
            
            self.credId = result.credentialInfo!.credId
            
            return result.credentialInfo!
        } else {
            throw PasskeySignerError.unexpected(code: PassKeyError.notSupported.rawValue, message: PassKeyError.notSupported.rawValue, error: nil)
        }
    }
    
    private func register(challenge: String, displayName: String, userId: String, completion: @escaping (DfnsApi.CredentialInfo?, PasskeySignerError?) -> Void) {
        passkey.register(relyingParty, challenge: challenge, displayName: displayName, userId: userId, securityKey: false,
          resolve: { authResult in
            let credentialInfo = DfnsApi.CredentialInfo(
                attestationData: (authResult["response"] as! NSDictionary)["rawAttestationObject"] as! String,
                clientData: (authResult["response"] as! NSDictionary)["rawClientDataJSON"] as! String,
                credId: authResult["credentialID"] as! String
            )
            completion(credentialInfo, nil)
        }, reject: { code, message, error in
            let exception = PasskeySignerError.unexpected(code: code, message: message, error: error)
            completion(nil, exception)
        })
    }
    
    public func sign(challenge: String) async throws -> DfnsApi.CredentialAssertion {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            let challenge = Utils.base64URLUnescaped(challenge)
            let result = await withCheckedContinuation { continuation in
                sign(challenge: challenge) { (credentialAssertion, exception) in
                    continuation.resume(returning: (credentialAssertion: credentialAssertion, exception: exception))
                }
            }
            
            if(result.exception != nil){
                throw result.exception!
            }
            
            return result.credentialAssertion!
        } else {
            throw PasskeySignerError.unexpected(code: PassKeyError.notSupported.rawValue, message: PassKeyError.notSupported.rawValue, error: nil)
        }
    }
    
    private func sign(challenge: String, completion: @escaping (DfnsApi.CredentialAssertion?, PasskeySignerError?) -> Void) {
        passkey.authenticate(relyingParty, challenge: challenge, securityKey: false, resolve: {authResult in
            let credentialAssertion = DfnsApi.CredentialAssertion(
                clientData: Utils.base64URLEscape((authResult["response"] as! NSDictionary)["rawClientDataJSON"] as! String),
                credId: Utils.base64URLEscape(self.credId!),
                signature: Utils.base64URLEscape((authResult["response"] as! NSDictionary)["signature"] as! String),
                authenticatorData: Utils.base64URLEscape((authResult["response"] as! NSDictionary)["rawAuthenticatorData"] as! String),
                userHandle: Utils.base64URLEscape((authResult["userID"] as! String).data(using: .utf8)!.base64EncodedString())
            )
            
            completion(credentialAssertion, nil)
        }, reject: { code, message, error in
            let exception = PasskeySignerError.unexpected(code: code, message: message, error: error)
            completion(nil, exception)
        })
    }
}
