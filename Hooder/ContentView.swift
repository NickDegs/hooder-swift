import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: GameStore

    @State private var selectedTab      = 0
    @State private var selectedHood:    HoodGroup?      = nil
    @State private var claimInfo:       PlaceClaimInfo? = nil
    @State private var selectedCity:    City?           = allCities.first
    @State private var showCityPicker   = false
    @State private var toastMsg:        String?
    @State private var pendingBuy:      Property?
    @State private var showBuyConfirm   = false

    private let allHoods = buildHoodGroups()

    private var isMapTab: Bool { selectedTab == 0 }

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── 1. Persistent 3D satellite map ────────────────────────────
            MapboxView(allHoods: allHoods, highlightKey: selectedHood?.key)
                .ignoresSafeArea()
                .onReceive(NotificationCenter.default.publisher(for: .mapSelectHood)) { note in
                    guard isMapTab, let h = note.userInfo?["hood"] as? HoodGroup else { return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedHood = h
                        claimInfo    = nil
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .mapSelectPlace)) { note in
                    guard isMapTab, let info = note.userInfo?["info"] as? PlaceClaimInfo else { return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        claimInfo    = info
                        selectedHood = nil
                    }
                }

            // ── 2. Map HUD ────────────────────────────────────────────────
            VStack(spacing: 0) {
                HStack {
                    cashBadge
                    Spacer()
                    cityPickerButton
                }
                .padding(.horizontal, Sp.lg)
                .padding(.top, Sp.lg)

                if showCityPicker {
                    cityChipsRow.transition(.opacity.combined(with: .move(edge: .top)))
                }
                Spacer()
            }
            .opacity(isMapTab ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isMapTab)

            // ── 3. Panels (priority: claim > hood) ────────────────────────
            if isMapTab, let info = claimInfo {
                PlaceClaimPanelView(info: info, onClose: { withAnimation { claimInfo = nil } })
                    .environmentObject(game)
                    .padding(.bottom, 82)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.38, dampingFraction: 0.85), value: claimInfo != nil)
                    .id(info.lat + info.lng)
            } else if isMapTab, let hood = selectedHood {
                NeighborhoodPanelView(hood: hood, onClose: { withAnimation { selectedHood = nil } })
                    .environmentObject(game)
                    .padding(.bottom, 82)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.38, dampingFraction: 0.85), value: hood.key)
                    .id(hood.key)
            }

            // ── 4. Screen panel (non-map tabs) ────────────────────────────
            if !isMapTab {
                contentPanel.transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // ── 5. Toast ──────────────────────────────────────────────────
            if let msg = toastMsg, isMapTab {
                Text(msg)
                    .font(.bodyBold).foregroundStyle(C.text)
                    .padding(.horizontal, Sp.lg).padding(.vertical, Sp.md)
                    .liquidGlass(in: Capsule())
                    .overlay(Capsule().stroke(C.border, lineWidth: 0.5))
                    .padding(.bottom, 100)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // ── 6. Tab bar ────────────────────────────────────────────────
            GlassTabBar(selectedTab: $selectedTab)
                .onChange(of: selectedTab) { _ in
                    if selectedTab != 0 {
                        withAnimation { selectedHood = nil; claimInfo = nil }
                    }
                }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selectedTab)
        .preferredColorScheme(.dark)
        .onAppear {
            // App Store ekran görüntüsü modu: sekmeleri otomatik gez (yalnız HOODER_SHOTS)
            guard ProcessInfo.processInfo.environment["HOODER_SHOTS"] == "1" else { return }
            var idx = 0
            Timer.scheduledTimer(withTimeInterval: 2.6, repeats: true) { _ in
                idx = (idx + 1) % 5
                withAnimation { selectedTab = idx }
            }
        }
    }

    // MARK: – HUD

    private var cashBadge: some View {
        HStack(spacing: Sp.xs) {
            Image(systemName: "dollarsign.circle.fill").foregroundStyle(C.gold)
            Text(formatPrice(game.cash)).font(.bodyBold).foregroundStyle(C.text)
        }
        .padding(.horizontal, Sp.md).padding(.vertical, Sp.sm)
        .liquidGlass(in: Capsule())
        .overlay(Capsule().stroke(C.specular, lineWidth: 0.5))
    }

    private var cityPickerButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showCityPicker.toggle() }
        } label: {
            HStack(spacing: Sp.xs) {
                Text(selectedCity?.flag ?? "🌍")
                Text(selectedCity?.name ?? "Şehir").font(.bodyBold).foregroundStyle(C.text)
                Image(systemName: showCityPicker ? "chevron.up" : "chevron.down")
                    .font(.caption_).foregroundStyle(C.textSub)
            }
            .padding(.horizontal, Sp.md).padding(.vertical, Sp.sm)
            .liquidGlass(in: Capsule())
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
                        withAnimation { showCityPicker = false }
                        NotificationCenter.default.post(name: .flyToCity, object: nil, userInfo: ["city": city])
                    } label: {
                        HStack(spacing: 4) {
                            Text(city.flag)
                            Text(city.name).font(.bodyBold)
                                .foregroundStyle(selectedCity?.id == city.id ? C.primary : C.text)
                        }
                        .padding(.horizontal, Sp.md).padding(.vertical, Sp.sm)
                        .background(selectedCity?.id == city.id ? C.primary.opacity(0.2) : Color.clear)
                        .liquidGlassFill()
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(selectedCity?.id == city.id ? C.primary : C.border, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Sp.lg).padding(.vertical, Sp.sm)
        }
    }

    // MARK: – Content Panel

    private var contentPanel: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.white.opacity(0.22))
                .frame(width: 36, height: 4)
                .padding(.top, Sp.md).padding(.bottom, 2)

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
        .liquidGlassFill()
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

    private func showToast(_ msg: String) {
        withAnimation { toastMsg = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { toastMsg = nil } }
    }
}
