import SwiftUI
import MapboxMaps
import GoogleSignIn

@main
struct HooderApp: App {

    @StateObject private var auth = AuthService()
    @StateObject private var game = GameStore()
    @State private var gameLoaded = false

    init() {
        MapboxOptions.accessToken = Bundle.main.infoDictionary?["MBXAccessToken"] as? String ?? ""

        // Configure Google Sign-In — only when a real OAuth client ID is present
        if let clientID = Bundle.main.infoDictionary?["GIDClientID"] as? String,
           clientID.hasSuffix(".apps.googleusercontent.com") {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isAuthenticated {
                    ContentView()
                        .environmentObject(game)
                        .environmentObject(auth)
                        .preferredColorScheme(.dark)
                        .onReceive(auth.$isAuthenticated) { isAuth in
                            if isAuth && !gameLoaded {
                                PersistenceService.shared.setUserID(auth.userID)
                                game.load()
                                gameLoaded = true
                            }
                        }
                } else {
                    LoginScreen()
                        .environmentObject(auth)
                        .preferredColorScheme(.dark)
                        .onReceive(auth.$isAuthenticated) { isAuth in
                            if isAuth && !gameLoaded {
                                PersistenceService.shared.setUserID(auth.userID)
                                game.load()
                                gameLoaded = true
                            }
                        }
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
