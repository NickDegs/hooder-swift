import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: GameStore

    var body: some View {
        TabView {
            MapScreen()
                .tabItem { Label("Harita", systemImage: "map.fill") }

            MarketScreen()
                .tabItem { Label("Piyasa", systemImage: "storefront.fill") }

            PortfolioScreen()
                .tabItem { Label("Portföy", systemImage: "chart.line.uptrend.xyaxis") }

            RankingsScreen()
                .tabItem { Label("Sıralama", systemImage: "trophy.fill") }

            SettingsScreen()
                .tabItem { Label("Ayarlar", systemImage: "gearshape.fill") }
        }
        .tint(C.primary)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .preferredColorScheme(.dark)
    }
}
