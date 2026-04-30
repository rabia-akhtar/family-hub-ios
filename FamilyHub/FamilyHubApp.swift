import SwiftUI
import GoogleSignIn

@main
struct FamilyHubApp: App {

    @StateObject private var appVM = AppViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if appVM.isSignedIn {
                    ContentView()
                        .environmentObject(appVM)
                } else {
                    AuthView()
                        .environmentObject(appVM)
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
