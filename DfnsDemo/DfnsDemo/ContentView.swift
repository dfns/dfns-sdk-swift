import SwiftUI

struct ContentView: View {
    @ObservedObject var userConfig: UserConfig
    @ObservedObject var myBusinessLogic: MyBusinessLogic
    
    var body: some View {
        NavigationView{
            ScrollView{
                VStack {
                    
                    /// INTRODUCTION
                    
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal, 120.0)
                    
                    Text("Introduction")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 15.0)
                    
                    Text("This tutorial app demonstrates how to use Dfns SDK in the following configuration:\n\n\u{2022}You have a server and a web single page application.\n\u{2022}You are not a custodian, and your customers own their wallets.\n\u{2022}Your customers will use WebAuthn (preferred) or a key credential (discourage as it comes with security risks) credentials to authenticate with Dfns.\n\u{2022}Your client applications communicates with your server, and does not call the Dfns API directly.\n\u{2022}Your server communicates with the Dfns API using a service account.")
                    
                    /// STEP 1
                    
                    Text("Step 1 - Delegated Registration")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 15.0)
                    
                    Text("Your customers, either new or existing, must register with Dfns first and have credential(s) in our system in order to own and be able to interact with their blockchain wallets.\n\nThe delegated registration flow allows you to initiate and and complete the registration process on your customers behalf, without them being aware that the wallets infrastructure is powered by Dfns, i.e. they will not receive an registration email from Dfns directly unlike the normal registration process for your employees. Their WebAuthn credentials are still completely under their control.")
                    
                    NavigationLink("Go to Delegated Registration",destination: DelegatedRegistrationView(userConfig: userConfig, myBusinessLogic: myBusinessLogic)).buttonStyle(.borderedProminent).padding(.vertical, 15)
                    
                    /// STEP 2
                    
                    Text("Step 2 - Delegated Login")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 15.0)
                    
                    Text("The delegated signing flow does not need the end user sign with the WebAuthn credential. The login can be performed on the server side transparent to the end users and obtain a readonly auth token. For example, your server can choose to automatically login the end users upon the completion of delegated registration. In this tutorial, this step is shown as explicit in order to more clearly demonstrate how the interaction works.")
                    
                    NavigationLink("Go to Delegated Login",destination: DelegatedLoginView(userConfig: userConfig, myBusinessLogic: myBusinessLogic)).buttonStyle(.borderedProminent).padding(.vertical, 15)
                    
                    /// STEP 3
                    
                    Text("Step 3 - Wallets")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 15.0)
                    
                    Text("Once logged in, the end users can use the wallets they own.")
                    
                    
                    if(userConfig.authToken != nil && userConfig.passkeysSigner != nil){
                        NavigationLink("Go to Wallets",destination: EndUserWalletsView(userConfig: userConfig, myBusinessLogic: myBusinessLogic)).buttonStyle(.borderedProminent).padding(.vertical, 15)
                    }else{
                        Text("⚠️ You need to complete step 1 and 2 first")
                    }
                    
                    Text("The end 🎉")
                        .font(.largeTitle).padding(.vertical, 15.0)
                    
                }
                .padding()
            }
        }
    }
}

struct DelegatedRegistrationView: View {
    @ObservedObject var userConfig: UserConfig
    @ObservedObject var myBusinessLogic: MyBusinessLogic
    @State var registerResponse: String = ""
    
    var body: some View {
        NavigationView{
            ScrollView{
                VStack{
                    Text("Delegated Registration")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 15.0)
                    
                    Text("For this tutorial, you will register a Dfns EndUser, and this is where the registration flow starts. However, in your final app, the flow may be different and the username might come from your internal system.")
                    
                    Text("After registration, the new end user will have an Ethereum testnet wallet and assigned the system permission, `DfnsDefaultEndUserAccess`, that grants the end user full access to their wallets.").padding(.vertical)
                    
                    Text("Enter the email as the username you are registering, and hit the \"Register EndUser\" button.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField("Choose a username", text: $userConfig.email).textFieldStyle(.roundedBorder).padding(.vertical)
                    
                    Button("Register EndUser"){
                        Task{
                            let result =  await myBusinessLogic.registerUser(email: userConfig.email)
                            userConfig.passkeysSigner = result.passkeysSigner
                            registerResponse = result.rawJSON
                        }
                    }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity).padding(.bottom)
                    
                    JSONText(registerResponse)
                }.padding()
            }
        }
    }
}

struct DelegatedLoginView: View {
    @ObservedObject var userConfig: UserConfig
    @ObservedObject var myBusinessLogic: MyBusinessLogic
    @State var loginResponse: String = ""
    
    var body: some View {
        NavigationView{
            ScrollView{
                VStack{
                    Text("Delegated Login")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 15.0)
                    
                    Text("For this tutorial, the delegated login flow is started on the client side by pressing the \"Login EndUser\" button. A request is sent to the server and a readonly auth token is returned in the response. This flow does not need users to sign with the WebAuthn credential.")
                    
                    Text("This auth token is readonly and needs to be cached and passed along with all requests interacting with the Dfns API. To clearly demonstrate all the necessary components for each step, this example will cache the auth token in the application context and send it back with every sequently request to the server. You should however choose a more secure caching method.").padding(.vertical)
                    
                    TextField("Enter the username", text: $userConfig.email).textFieldStyle(.roundedBorder)
                    
                    Button("Login EndUser"){
                        Task{
                            let result = await myBusinessLogic.delegatedLogin(email: userConfig.email)
                            loginResponse = result.rawJSON
                            userConfig.authToken = result.authToken
                        }
                    }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity).padding(.vertical)
                    
                    JSONText(loginResponse)
                    
                }.padding()
            }
        }
    }
}

struct EndUserWalletsView: View {
    @ObservedObject var userConfig: UserConfig
    @ObservedObject var myBusinessLogic: MyBusinessLogic
    @State var walletResponse: String = ""
    @State var messageToSign: String = ""
    @State var signingResponse: String = ""
    @State var walletId: String = ""
    
    var body: some View {
        NavigationView{
            ScrollView{
                VStack{
                    Text("End User Wallets")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 15.0)
                    
                    Text("The Ethereum testnet wallet created for the end user during registration is listed below. Listing wallets only needs the readonly auth token. End users won't be prompted to use their WebAuthn credentials.")
                    
                    JSONText(walletResponse).padding(.vertical)
                    
                    Text("Use wallets to broadcast transactions will require the end users to sign a challenge each time to authorize the action. For this tutorial, because new wallets do not have any native tokens to pay for gas fees, we won't be able to broadcast any transactions to chain. Instead, we will sign an arbitrary message that can be used as proof the end user is the owner of the private key secured by Dfns.")
                    
                    Text("Enter a message in the input box and press the \"Sign Message\" button. You will see a WebAuthn prompt asking for authorization to perform the action. Once granted, the tutorial makes a request to Dfns MPC signers and gets a signature hash. Optionally you can use etherscan to verify this signature hash matches the wallet address.").padding(.vertical)
                    
                    TextField("Enter your message", text: $messageToSign).textFieldStyle(.roundedBorder)
                    
                    Button("Sign Message"){
                        Task{
                            signingResponse = await myBusinessLogic.signMessage(message: messageToSign, walletId: walletId, authToken: userConfig.authToken!, passkeysSigner: userConfig.passkeysSigner!)
                            
                        }
                    }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity).padding(.vertical)
                    
                    JSONText(signingResponse)
                    
                }.padding().onAppear {
                    Task{
                        let listWalletsResult = await myBusinessLogic.listWallets(authToken: userConfig.authToken!)
                        
                        walletResponse = listWalletsResult.rawJSON
                        walletId = listWalletsResult.walletId
                    }
                }
            }
        }
    }
}

struct JSONText: View {
    var prettyJSON: String = ""
    
    init(_ text: String){
        do{
            let json = try JSONSerialization.jsonObject(with: text.data(using: .utf8)!, options: .mutableContainers)
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            prettyJSON = String(data: jsonData, encoding: .utf8)!
        }catch{
            prettyJSON = text
        }
    }
    
    var body: some View{
        Text(prettyJSON).font(.footnote).padding().foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading).background(.black)
    }
}

#Preview {
    EndUserWalletsView(userConfig: UserConfig(), myBusinessLogic: MyBusinessLogic( url: Config.url, appId: Config.appId))
}
