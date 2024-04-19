import DfnsSdk
import Foundation

/**
    Implement the API of the server
 */
final class MyServer {
    private var url: String = ""

    init(url: String) {
        self.url = url
    }

    typealias ServerResponse<T> = (rawJSON: String, response: T)

    struct Ignore: Codable {}

    public func registerInit(appId: String, username: String) async -> ServerResponse<DfnsApi.UserRegistrationChallenge> {
        struct RegisterInit: Codable {
            let appId: String
            let username: String
        }

        return await makeRequest(
            path: "/register/init",
            body: RegisterInit(appId: appId, username: username),
            decoder: DfnsApi.UserRegistrationChallenge.self
        )
    }

    struct SignedChallenge: Codable {
        let firstFactorCredential: DfnsApi.Fido2Attestation
    }

    public func registerComplete(appId: String, signedChallenge: SignedChallenge, temporaryAuthenticationToken: String) async -> ServerResponse<Ignore> {
        struct RegisterComplete: Codable {
            let appId: String
            let signedChallenge: SignedChallenge
            let temporaryAuthenticationToken: String
        }

        return await makeRequest(
            path: "/register/complete",
            body: RegisterComplete(appId: appId, signedChallenge: signedChallenge, temporaryAuthenticationToken: temporaryAuthenticationToken),
            decoder: Ignore.self
        )
    }

    struct LoginResponse: Codable {
        let username: String
        let token: String
    }

    public func login(username: String) async -> ServerResponse<LoginResponse> {
        struct LoginRequest: Codable {
            let username: String
        }

        return await makeRequest(
            path: "/login",
            body: LoginRequest(username: username),
            decoder: LoginResponse.self
        )
    }

    struct Wallet: Codable {
        // We partially decode the Wallet object
        let id: String
    }

    struct ListWalletResponse: Codable {
        let items: [Wallet]
    }

    public func listWallets(appId: String, authToken: String) async -> ServerResponse<ListWalletResponse> {
        struct ListWallets: Codable {
            let appId: String
            let authToken: String
        }

        return await makeRequest(
            path: "/wallets/list",
            body: ListWallets(appId: appId, authToken: authToken),
            decoder: ListWalletResponse.self
        )
    }

    struct InitSignatureResponse: Codable {
        let requestBody: RequestBody
        let challenge: DfnsApi.UserActionChallenge
    }

    struct RequestBody: Codable {
        let kind: String
        let message: String
    }

    public func initSignature(message: String, walletId: String, appId: String, authToken: String) async -> ServerResponse<InitSignatureResponse> {
        struct InitSignature: Codable { let message: String; let walletId: String; let appId: String; let authToken: String }

        return await makeRequest(
            path: "/wallets/signatures/init",
            body: InitSignature(message: message, walletId: walletId, appId: appId, authToken: authToken),
            decoder: InitSignatureResponse.self
        )
    }

    public func completeSignature(walletId: String, appId: String, authToken: String, requestBody: RequestBody, signedChallenge: DfnsApi.UserActionAssertion) async -> ServerResponse<Ignore> {
        struct InitSignature: Codable { let message: String; let walletId: String; let appId: String; let authToken: String }

        struct CompleteSignature: Codable {
            let walletId: String
            let appId: String
            let authToken: String
            let requestBody: RequestBody
            let signedChallenge: DfnsApi.UserActionAssertion
        }

        return await makeRequest(
            path: "/wallets/signatures/complete",
            body: CompleteSignature(walletId: walletId, appId: appId, authToken: authToken, requestBody: requestBody, signedChallenge: signedChallenge),
            decoder: Ignore.self
        )
    }

    private func makeRequest<T: Codable>(path: String, body: Codable, decoder _: T.Type) async -> (rawJSON: String, response: T) {
        let encoder = JSONEncoder()
        // requestBody needs to follow the same order returned by the API
        encoder.outputFormatting = [.sortedKeys]

        var request = URLRequest(url: URL(string: "\(url)\(path)")!)
        request.httpMethod = "POST"
        request.httpBody = (try? encoder.encode(body))!
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try! await URLSession.shared.data(for: request)
        let response: T = try! JSONDecoder().decode(T.self, from: data)

        return (rawJSON: String(data: data, encoding: .utf8)!, response: response)
    }
}
