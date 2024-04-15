import Foundation

public enum PasskeySignerError: Error {
    // Throw in all other cases
    case unexpected(code: String?, message: String?, error: String?)
}

public final class PasskeySigner{
    private var passkey = Passkey()
    private var appOrigin: String
    private var credId: String?
    private var relyingParty: String
    
    public init(appOrigin: String, relyingParty: String){
        self.appOrigin = appOrigin
        self.relyingParty = relyingParty
    }
    
    public func register(challenge: String, displayName: String, userId: String) throws -> DfnsApi.CredentialInfo {
        var credentialInfo: DfnsApi.CredentialInfo?
        var exception: (code: String?, message: String?, error: String?)?
        let challenge = Utils.base64URLUnescaped(challenge)
        
        let semaphore = DispatchSemaphore(value: 0)
        
        passkey.register(relyingParty, challenge: challenge, displayName: displayName, userId: userId, securityKey: false,
          resolve: { authResult in
            credentialInfo = DfnsApi.CredentialInfo(
                attestationData: (authResult["response"] as! NSDictionary)["rawAttestationObject"] as! String,
                clientData: (authResult["response"] as! NSDictionary)["rawClientDataJSON"] as! String,
                credId: authResult["credentialID"] as! String
            )
            semaphore.signal()
        }, reject: { code, message, error in
            exception = (code: code, message: message, error: error)
            semaphore.signal()
        })
        
        semaphore.wait()
        if(exception != nil){
            throw PasskeySignerError.unexpected(code: exception!.code, message: exception!.message, error: exception!.error)
        }
        
        self.credId = credentialInfo!.credId
        
        return credentialInfo!
    }
    
    public func sign(challenge: String) throws -> DfnsApi.CredentialAssertion {
        var credentialAssertion: DfnsApi.CredentialAssertion?
        var exception: (code: String?, message: String?, error: String?)?
        
        let semaphore = DispatchSemaphore(value: 0)
        passkey.authenticate(relyingParty, challenge: challenge, securityKey: false, resolve: {authResult in
            credentialAssertion = DfnsApi.CredentialAssertion(
                clientData: Utils.base64URLEscape((authResult["response"] as! NSDictionary)["rawClientDataJSON"] as! String),
                credId: Utils.base64URLEscape(self.credId!),
                signature: Utils.base64URLEscape((authResult["response"] as! NSDictionary)["signature"] as! String),
                authenticatorData: Utils.base64URLEscape((authResult["response"] as! NSDictionary)["rawAuthenticatorData"] as! String),
                userHandle: Utils.base64URLEscape((authResult["userID"] as! String).data(using: .utf8)!.base64EncodedString())
            )
            semaphore.signal()
        }, reject: { code, message, error in
            exception = (code: code, message: message, error: error)
            semaphore.signal()
        })
        semaphore.wait()
        if(exception != nil){
            throw PasskeySignerError.unexpected(code: exception!.code, message: exception!.message, error: exception!.error)
        }
        
        return credentialAssertion!
    }
}
