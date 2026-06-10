import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: GameStore

    @State private var selectedTab = 0

    // Map state
    @State private var selectedProperty: Property?
    @State private var selectedCity: City? = allCities.first
    @State private var showCityPicker = false
    @State private var pendingBuy: Property?
    @State private var showBuyConfirm = false
    @State private var toastMsg: String?

    private var isMapTab: Bool { selectedTab == 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── 1. Persistent 3D satellite map (always rendered) ──────────
            MapboxView(properties: allProperties, selectedProperty: $selectedProperty)
                .ignoresSafeArea()

            // ── 2. Map HUD (cash badge + city picker) ─────────────────────
            VStack(spacing: 0) {
                HStack {
                    cashBadge
                    Spacer()
                    cityPickerButton
                }
                .padding(.horizontal, Sp.lg)
                .padding(.top, Sp.lg)

                if showCityPicker {
                    cityChipsRow
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                Spacer()
            }
            .opacity(isMapTab ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isMapTab)

            // ── 3. Property detail panel (map pin tap) ────────────────────
            if let prop = selectedProperty, isMapTab {
                PropertyDetailPanel(
                    property: prop,
                    onClose: { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedProperty = nil } },
                    onBuy:   { pendingBuy = prop; showBuyConfirm = true }
                )
                .padding(.bottom, 88)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedProperty?.id)
            }

            // ── 4. Glass content panel for non-map tabs ───────────────────
            if !isMapTab {
                contentPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // ── 5. Map toast ───────────────────────────────────────────────
            if let msg = toastMsg, isMapTab {
                Text(msg)
                    .font(.bodyBold)
                    .foregroundStyle(C.text)
                    .padding(.horizontal, Sp.lg)
                    .padding(.vertical, Sp.md)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(C.border, lineWidth: 0.5))
                    .padding(.bottom, 100)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // ── 6. Floating glass tab bar (always on top) ─────────────────
            GlassTabBar(selectedTab: $selectedTab)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selectedTab)
        .preferredColorScheme(.dark)
        .confirmationDialog(
            pendingBuy.map { "Satın al: \($0.name)" } ?? "",
            isPresented: $showBuyConfirm,
            titleVisibility: .visible
        ) {
            if let prop = pendingBuy {
                Button("Satın Al — \(formatPrice(prop.price))") { doBuy(prop) }
                Button("İptal", role: .cancel) {}
            }
        } message: {
            if let prop = pendingBuy {
                Text("Mevcut bakiye: \(formatPrice(game.cash))")
            }
        }
    }

    // MARK: – Map HUD

    private var cashBadge: some View {
        HStack(spacing: Sp.xs) {
            Image(systemName: "dollarsign.circle.fill").foregroundStyle(C.gold)
            Text(formatPrice(game.cash)).font(.bodyBold).foregroundStyle(C.text)
        }
        .padding(.horizontal, Sp.md)
        .padding(.vertical, Sp.sm)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(C.specular, lineWidth: 0.5))
    }

    private var cityPickerButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showCityPicker.toggle() }
        } label: {
            HStack(spacing: Sp.xs) {
                Text(selectedCity?.flag ?? "🌍")
                Text(selectedCity?.name ?? "Şehir")
                    .font(.bodyBold).foregroundStyle(C.text)
                Image(systemName: showCityPicker ? "chevron.up" : "chevron.down")
                    .font(.caption_).foregroundStyle(C.textSub)
            }
            .padding(.horizontal, Sp.md)
            .padding(.vertical, Sp.sm)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(C.specular, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var cityChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Sp.sm) {
                ForEach(allCities) { city in
                    Button {
                        selectedCity = city
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showCityPicker = false }
                        NotificationCenter.default.post(name: .flyToCity, object: nil, userInfo: ["city": city])
                    } label: {
                        HStack(spacing: 4) {
                            Text(city.flag)
                            Text(city.name).font(.bodyBold)
                                .foregroundStyle(selectedCity?.id == city.id ? C.primary : C.text)
                        }
                        .padding(.horizontal, Sp.md)
                        .padding(.vertical, Sp.sm)
                        .background(selectedCity?.id == city.id ? C.primary.opacity(0.2) : Color.clear)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(selectedCity?.id == city.id ? C.primary : C.border, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Sp.lg)
            .padding(.vertical, Sp.sm)
        }
    }

    // MARK: – Content Panel

    private var contentPanel: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.white.opacity(0.22))
                .frame(width: 36, height: 4)
                .padding(.top, Sp.md)
                .padding(.bottom, 2)

            // Tab screen
            Group {
                switch selectedTab {
                case 1: MarketScreen()
                case 2: PortfolioScreen()
                case 3: RankingsScreen()
                case 4: SettingsScreen()
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.76)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: R.x2, style: .continuous)
                .stroke(C.specular, lineWidth: 0.5)
                .frame(height: UIScreen.main.bounds.height * 0.76)
        }
        .clipShape(RoundedRectangle(cornerRadius: R.x2, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 28, y: -6)
        .padding(.horizontal, Sp.xs)
        .padding(.bottom, 82)
    }

    // MARK: – Helpers

    private func doBuy(_ prop: Property) {
        let ok = game.buy(prop)
        showToast(ok ? "\(prop.name) satın alındı!" : "Yetersiz bakiye!")
        if ok { withAnimation { selectedProperty = nil } }
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMsg = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { toastMsg = nil } }
    }
}
