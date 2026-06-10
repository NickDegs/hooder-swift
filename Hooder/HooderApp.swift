import SwiftUI
import MapboxMaps

@main
struct HooderApp: App {

    @StateObject private var auth = AuthService()
    @StateObject private var game = GameStore()
    @State private var gameLoaded = false

    init() {
        MapboxOptions.accessToken = Bundle.main.infoDictionary?["MBXAccessToken"] as? String ?? ""
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
