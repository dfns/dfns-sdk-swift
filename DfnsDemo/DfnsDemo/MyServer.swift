import Foundation
import DfnsSdk

/**
    Implement the API of the server
 */
final class MyServer {
    
    private var url: String = ""
    
    init(url: String) {
        self.url = url
    }
    
    typealias ServerResponse<T> = (rawResponse: String, response: T)
    
    struct Ignore: Codable{}
    
    public func registerInit(appId: String, username: String) async -> ServerResponse<DfnsApi.CreateDelegatedUserRegistrationResponse>  {
        struct RegisterInit : Codable{
            let appId: String
            let username: String
        }
        
        return await self.makeRequest(
            path: "/register/init",
            body: RegisterInit(appId: appId, username: username),
            decoder: DfnsApi.CreateDelegatedUserRegistrationResponse.self
        )
    }
    
    struct SignedChallenge : Codable {
        let firstFactorCredential: DfnsApi.FirstFactorCredential
    }
    
    public func registerComplete(appId: String, signedChallenge: SignedChallenge, temporaryAuthenticationToken: String) async -> ServerResponse<Ignore>  {
        
        struct RegisterComplete : Codable{
            let appId: String
            let signedChallenge: SignedChallenge
            let temporaryAuthenticationToken: String
        }
        
        return await self.makeRequest(
            path: "/register/complete",
            body: RegisterComplete(appId: appId, signedChallenge: signedChallenge, temporaryAuthenticationToken: temporaryAuthenticationToken),
            decoder: Ignore.self
        )
    }
    
    struct LoginResponse : Codable{
        let username: String
        let token: String
    }
    
    public func login(username: String) async -> ServerResponse<LoginResponse> {
        struct LoginRequest : Codable{
            let username: String
        }
        
        return await self.makeRequest(
            path: "/login",
            body: LoginRequest(username: username),
            decoder: LoginResponse.self
        )
    }

    public func listWallets(appId: String, authToken: String) async -> ServerResponse<Ignore>{
        struct ListWallets: Codable{
            let appId: String
            let authToken: String
        }
        
        return await self.makeRequest(
            path: "/wallets/list",
            body: ListWallets(appId: appId, authToken: authToken),
            decoder: Ignore.self
        )
    }
    
    struct InitWalletResponse: Codable{
        let requestBody: RequestBody
        let challenge: DfnsApi.AuthActionInitResponse
    }
    
    struct RequestBody: Codable{
        let network: String
    }
    
    public func initWallet(appId: String, authToken: String) async -> ServerResponse<InitWalletResponse> {
        struct InitWallet: Codable{ let appId: String ; let authToken: String }
        
        return await self.makeRequest(
            path: "/wallets/new/init",
            body: InitWallet(appId: appId, authToken: authToken),
            decoder: InitWalletResponse.self
        )
    }
    
    public func completeWallet(appId: String, authToken: String, requestBody: RequestBody, signedChallenge: DfnsApi.AuthActionRequest) async -> ServerResponse<Ignore> {
        struct CompleteWallet: Codable{
            let appId: String
            let authToken: String
            let requestBody: RequestBody
            let signedChallenge: DfnsApi.AuthActionRequest
        }
        
        return await self.makeRequest(
            path: "/wallets/new/complete",
            body: CompleteWallet(appId: appId, authToken: authToken, requestBody: requestBody, signedChallenge: signedChallenge),
            decoder: Ignore.self
        )
    }

    private func makeRequest<T: Codable>(path: String, body: Codable, decoder: T.Type) async  -> (rawResponse: String, response: T)  {
        var request = URLRequest(url: URL(string: "\(self.url)\(path)")!)
        request.httpMethod = "POST"
        request.httpBody = (try? JSONEncoder().encode(body))!
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try! await URLSession.shared.data(for: request)
        let response: T = try! JSONDecoder().decode(T.self, from: data)
        
        return (rawResponse: String(data: data, encoding: .utf8)!, response: response)
    }
    
}

