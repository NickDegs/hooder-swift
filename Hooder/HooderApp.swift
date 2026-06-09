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

        // Configure Google Sign-In if client ID is set
        if let clientID = Bundle.main.infoDictionary?["GIDClientID"] as? String,
           !clientID.isEmpty, clientID != "PLACEHOLDER" {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }

    var body: some Scene {
        WindowGroup {
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
    }
}
