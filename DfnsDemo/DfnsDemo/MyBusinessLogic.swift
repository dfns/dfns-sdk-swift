import DfnsSdk
import Foundation
import Observation

/**
    Controller that is doing the interface between the UI, the Demo Server and the Passkey Signer
 */
@Observable
@MainActor
final class MyBusinessLogic: @unchecked Sendable {
    private var passkeyRelyingPartyId: String
    private let myServer: MyServer
    private let passkeysSigner: PasskeysSigner

    init(url: String, passkeyRelyingPartyId: String) {
        self.passkeyRelyingPartyId = passkeyRelyingPartyId
        self.myServer = MyServer(url: url)
        self.passkeysSigner = PasskeysSigner(relyingPartyId: passkeyRelyingPartyId)
    }

    /**
     Step 1 of our demo. Register the user. The process is in 2 steps, first we retrieve a challenge that we sign with the passkeys signer, then we complete the registration.

     - Parameter email: Email address of the user

     - Returns: Tuple containing the response from our server API and the passkeySigner
     */
    public func registerUser(userConfig: UserConfig) async -> String {
        let registerInitResponse = (await self.myServer.registerInit(username: userConfig.email)).response
        let fido2Attestation = try! await self.passkeysSigner.register(challenge: registerInitResponse)
        let signedChallenge = MyServer.SignedChallenge(firstFactorCredential: fido2Attestation)
        let result = await self.myServer.registerComplete(signedChallenge: signedChallenge, temporaryAuthenticationToken: registerInitResponse.temporaryAuthenticationToken)

        return result.rawJSON
    }

    /**
     Step 2 of our demo. Log the user

     - Parameter email: Email address of the user

     - Returns: Tuple containing the response from our server API and the authToken to be used in Step 3.
     */
    public func delegatedLogin(email: String) async -> (rawJSON: String, authToken: String) {
        let result = await self.myServer.login(username: email)
        return (rawJSON: result.rawJSON, authToken: result.response.token)
    }

    /**
     Step 3 of our demo. For a given authToken retrieve the users wallets as a JSON string

     - Parameters:
        - authToken: Authentication token retrieved in Step 2
     */
    public func listWallets(authToken: String) async -> (rawJSON: String, walletId: String) {
        let result = await self.myServer.listWallets(authToken: authToken)

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
    public func signMessage(message: String, walletId: String, authToken: String) async -> String {
        let initWalletResult = await self.myServer.initSignature(message: message, walletId: walletId, authToken: authToken)
        let fido2Assertion = try! await self.passkeysSigner.sign(challenge: initWalletResult.response.challenge)
        let userActionAssertion = DfnsApi.UserActionAssertion(challengeIdentifier: initWalletResult.response.challenge.challengeIdentifier, firstFactor: fido2Assertion)
        let result = await self.myServer.completeSignature(walletId: walletId, authToken: authToken, requestBody: initWalletResult.response.requestBody, signedChallenge: userActionAssertion)

        return result.rawJSON
    }
}
