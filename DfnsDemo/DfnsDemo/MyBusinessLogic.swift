import Foundation
import DfnsSdk

/**
    Controller that is doing the interface between the UI, the Demo Server and the Passkey Signer
 */
final class MyBusinessLogic: ObservableObject {
    
    private var appId: String
    private var relyingParty: String
    private var myServer: MyServer
    private var appOrigin: String
    
    init(url: String, appId: String, relyingParty: String, appOrigin: String) {
        self.appId = appId
        self.relyingParty = relyingParty
        self.myServer = MyServer(url: url)
        self.appOrigin = appOrigin
    }
    
    /**
     Step 1 of our demo. Register the user. The process is in 2 steps, first we retrieve a challenge that we sign with the pass key signer, then we complete the registration.

     - Parameter username: Email address of the user

     - Returns: Tuple containing the response from our server API and the passkeySigner
     */
    public func registerUser(email: String) async -> (result: String, passkeySigner: PasskeySigner) {
        let passkeySigner = PasskeySigner(appOrigin: appOrigin, relyingParty: relyingParty)

        let registerInitResponse = (await myServer.registerInit(appId: self.appId, username: email)).response
        
        let credentialInfo = try! await passkeySigner.register(
            challenge: registerInitResponse.challenge,
            displayName: email,
            userId: registerInitResponse.user.id)
        
        let signedChallenge = MyServer.SignedChallenge(firstFactorCredential: DfnsApi.FirstFactorCredential(credentialInfo: credentialInfo, credentialKind: "Fido2"))

        let result = await myServer.registerComplete(appId: self.appId, signedChallenge: signedChallenge, temporaryAuthenticationToken: registerInitResponse.temporaryAuthenticationToken)

        return (result: result.rawResponse, passkeySigner: passkeySigner)
    }
    
    /**
     Step 2 of our demo. Log the user

     - Parameter username: Email address of the user

     - Returns: Tuple containing the response from our server API and the authToken to be used in Step 3.
     */
    public func delegatedLogin(email: String) async -> (rawJSON: String, authToken: String) {
        let result = await myServer.login(username: email)
        return (rawJSON: result.rawResponse, authToken: result.response.token)
    }
    
    /**
     Step 3 of our demo. For a given authToken retrieve the users wallets as a JSON string

     - Parameters:
        - passkeySigner: passkey signer created in Step 1
        - authToken: Authentication token retrieved in Step 2
     */
    public func listWallets(authToken: String) async -> (rawJSON: String, walletId: String){
        let result = await myServer.listWallets(appId: self.appId, authToken: authToken)
        
        let walletId = result.response.items[0].id
        return (rawJSON: result.rawResponse, walletId: walletId)
    }
    
    /**
     Step 3 of our demo. Create wallets using the passkey signer

     - Parameters:
        - passkeySigner: passkey signer created in Step 1
        - authToken: Authentication token retrieved in Step 2
     */
    public func signMessage(message: String, walletId: String, authToken: String, passkeySigner: PasskeySigner) async -> String {
        let initWalletResult = await myServer.initSignature(message: message, walletId: walletId, appId: self.appId, authToken: authToken)
        let credentialAssertion = try! await passkeySigner.sign(challenge: Utils.base64URLUnescaped(initWalletResult.response.challenge.challenge))
        let firstFactor = DfnsApi.FirstFactor(kind: "Fido2", credentialAssertion: credentialAssertion)
        let authActionRequest = DfnsApi.AuthActionRequest(challengeIdentifier: initWalletResult.response.challenge.challengeIdentifier, firstFactor: firstFactor)
        let result = await myServer.completeSignature(walletId: walletId, appId: self.appId, authToken: authToken, requestBody: initWalletResult.response.requestBody, signedChallenge: authActionRequest)
        
        return result.rawResponse
    }
}

