import DfnsSdk
import SwiftUI
import Observation

@Observable
final class UserConfig {
	var authToken: String?
	var email: String
	
    init() {
		email = ""
    }

}

@main
struct DfnsDemoApp: App {
    @State private var userConfig = UserConfig()
    @State private var myBusinessLogic = MyBusinessLogic(
        url: Config.serverUrl,
        passkeyRelyingPartyId: Config.passkeyRelyingPartyId
    )

    var body: some Scene {
        WindowGroup {
			ContentView(userConfig: $userConfig, myBusinessLogic: myBusinessLogic)
        }
    }
}
