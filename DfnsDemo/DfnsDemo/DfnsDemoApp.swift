import SwiftUI
import DfnsSdk

class UserConfig: ObservableObject {
    init(){email = ""}
    @Published var authToken: String?
    @Published var passkeysSigner: PasskeysSigner?
    @Published var email: String
}

@main
struct DfnsDemoApp: App {
    @StateObject private var userConfig = UserConfig()
    @StateObject private var myBusinessLogic = MyBusinessLogic(
        url: Config.url,
        appId: Config.appId
    )
        
    var body: some Scene {
        WindowGroup {
            ContentView(userConfig: userConfig, myBusinessLogic: myBusinessLogic)
        }
    }
}
