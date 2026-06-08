import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var game: GameStore

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab pages — no system tab bar
            Group {
                switch selectedTab {
                case 0: MapScreen().ignoresSafeArea()
                case 1: PortfolioScreen()
                case 2: MarketScreen()
                case 3: RankingsScreen()
                case 4: SettingsScreen()
                default: MapScreen().ignoresSafeArea()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .background(C.bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}
