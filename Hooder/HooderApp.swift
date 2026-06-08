import SwiftUI
import MapboxMaps

@main
struct HooderApp: App {

    @StateObject private var game = GameStore()

    init() {
        MapboxOptions.accessToken = Bundle.main.infoDictionary?["MBXAccessToken"] as? String ?? ""
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
                .preferredColorScheme(.dark)
        }
    }
}
