import DfnsSdk
import Foundation

/**
    Controller that is doing the interface between the UI, the Demo Server and the Passkey Signer
 */
final class MyBusinessLogic: ObservableObject {
    private var appId: String
    private var myServer: MyServer

    init(url: String, appId: String) {
        self.appId = appId
        myServer = MyServer(url: url)
    }

    /**
     Step 1 of our demo. Register the user. The process is in 2 steps, first we retrieve a challenge that we sign with the passkeys signer, then we complete the registration.

     - Parameter email: Email address of the user

     - Returns: Tuple containing the response from our server API and the passkeySigner
     */
    public func registerUser(email: String) async -> (rawJSON: String, passkeysSigner: PasskeysSigner) {
        let passkeysSigner = PasskeysSigner()
        let registerInitResponse = (await myServer.registerInit(appId: appId, username: email)).response
        let fido2Attestation = try! await passkeysSigner.register(challenge: registerInitResponse)
        let signedChallenge = MyServer.SignedChallenge(firstFactorCredential: fido2Attestation)
        let result = await myServer.registerComplete(appId: appId, signedChallenge: signedChallenge, temporaryAuthenticationToken: registerInitResponse.temporaryAuthenticationToken)

        return (rawJSON: result.rawJSON, passkeysSigner: passkeysSigner)
    }

    /**
     Step 2 of our demo. Log the user

     - Parameter email: Email address of the user

     - Returns: Tuple containing the response from our server API and the authToken to be used in Step 3.
     */
    public func delegatedLogin(email: String) async -> (rawJSON: String, authToken: String) {
        let result = await myServer.login(username: email)
        return (rawJSON: result.rawJSON, authToken: result.response.token)
    }

    /**
     Step 3 of our demo. For a given authToken retrieve the users wallets as a JSON string

     - Parameters:
        - authToken: Authentication token retrieved in Step 2
     */
    public func listWallets(authToken: String) async -> (rawJSON: String, walletId: String) {
        let result = await myServer.listWallets(appId: appId, authToken: authToken)

        let walletId = result.response.items[0].id
        return (rawJSON: result.rawJSON, walletId: walletId)
    }

    /**
     Step 3 of our demo. Sign a message using the passkeys signer

     - Parameters:
        - message: message to be signed
        - walletId: id of the wallet created during user registration (retrieved through `listWallets`)
        - authToken: Authentication token retrieved in Step 2
        - passkeySigner: passkeys signer created in Step 1
     */
    public func signMessage(message: String, walletId: String, authToken: String, passkeysSigner: PasskeysSigner) async -> String {
        let initWalletResult = await myServer.initSignature(message: message, walletId: walletId, appId: appId, authToken: authToken)
        let fido2Assertion = try! await passkeysSigner.sign(challenge: initWalletResult.response.challenge)
        let userActionAssertion = DfnsApi.UserActionAssertion(challengeIdentifier: initWalletResult.response.challenge.challengeIdentifier, firstFactor: fido2Assertion)
        let result = await myServer.completeSignature(walletId: walletId, appId: appId, authToken: authToken, requestBody: initWalletResult.response.requestBody, signedChallenge: userActionAssertion)

        return result.rawJSON
    }
}
