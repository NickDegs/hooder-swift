import SwiftUI

enum SortOption: String, CaseIterable {
    case price    = "Fiyat"
    case income   = "Günlük Gelir"
    case roi      = "ROI"
    case prestige = "Prestij"
}

struct MarketScreen: View {
    @EnvironmentObject var game: GameStore

    @State private var searchText     = ""
    @State private var selectedCat: PropertyCategory? = nil
    @State private var selectedCity: String? = nil
    @State private var sortOption: SortOption = .price
    @State private var sortAsc = true
    @State private var showSortMenu = false
    @State private var buyTarget: Property?
    @State private var showBuyConfirm = false
    @State private var toastMsg: String?

    var filtered: [Property] {
        var list = allProperties

        if let cat = selectedCat { list = list.filter { $0.category == cat } }
        if let city = selectedCity { list = list.filter { $0.city == city } }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.name.lowercased().contains(q) ||
                $0.city.lowercased().contains(q) ||
                $0.neighborhood.lowercased().contains(q)
            }
        }

        list.sort {
            switch sortOption {
            case .price:    return sortAsc ? $0.price < $1.price : $0.price > $1.price
            case .income:   return sortAsc ? $0.incomePerDay < $1.incomePerDay : $0.incomePerDay > $1.incomePerDay
            case .roi:      return sortAsc ? $0.roiPercent < $1.roiPercent : $0.roiPercent > $1.roiPercent
            case .prestige: return sortAsc ? $0.prestige < $1.prestige : $0.prestige > $1.prestige
            }
        }
        return list
    }

    var cities: [String] { Array(Set(allProperties.map { $0.city })).sorted() }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search + sort header
                VStack(spacing: Sp.sm) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(C.textMuted)
                        TextField("Mülk veya şehir ara...", text: $searchText)
                            .font(.body_)
                            .foregroundColor(C.text)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, Sp.md)
                    .padding(.vertical, Sp.sm)
                    .background(C.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: R.md))

                    // Category chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Sp.sm) {
                            chipButton("Tümü", active: selectedCat == nil) { selectedCat = nil }
                            ForEach(PropertyCategory.allCases, id: \.self) { cat in
                                chipButton("\(cat.emoji) \(cat.label)", active: selectedCat == cat) {
                                    selectedCat = selectedCat == cat ? nil : cat
                                }
                            }
                        }
                        .padding(.horizontal, 1)
                    }

                    // City chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Sp.sm) {
                            chipButton("Tüm Şehirler", active: selectedCity == nil) { selectedCity = nil }
                            ForEach(allCities) { city in
                                chipButton("\(city.flag) \(city.name)", active: selectedCity == city.name) {
                                    selectedCity = selectedCity == city.name ? nil : city.name
                                }
                            }
                        }
                        .padding(.horizontal, 1)
                    }

                    // Sort row
                    HStack {
                        Text("\(filtered.count) mülk")
                            .font(.caption_)
                            .foregroundColor(C.textMuted)
                        Spacer()
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { opt in
                                Button {
                                    if sortOption == opt { sortAsc.toggle() }
                                    else { sortOption = opt; sortAsc = true }
                                } label: {
                                    Label(opt.rawValue, systemImage: sortOption == opt
                                          ? (sortAsc ? "arrow.up" : "arrow.down")
                                          : "")
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(sortOption.rawValue)
                                    .font(.caption_)
                                Image(systemName: sortAsc ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(C.primary)
                        }
                    }
                }
                .padding(.horizontal, Sp.lg)
                .padding(.bottom, Sp.sm)
                .background(C.bg)

                Divider().background(C.border)

                // List
                ScrollView {
                    LazyVStack(spacing: Sp.md) {
                        ForEach(filtered) { prop in
                            marketRow(prop)
                                .padding(.horizontal, Sp.lg)
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.top, Sp.md)
                }
                .background(C.bg)
            }
            .background(C.bg.ignoresSafeArea())
            .navigationTitle("Piyasa")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottom) {
                if let msg = toastMsg {
                    Text(msg)
                        .font(.bodyBold)
                        .foregroundColor(C.text)
                        .padding(.horizontal, Sp.lg)
                        .padding(.vertical, Sp.md)
                        .background(C.bgCard)
                        .clipShape(Capsule())
                        .padding(.bottom, 100)
                        .transition(.opacity)
                }
            }
        }
        .confirmationDialog(
            buyTarget != nil ? "Satın al: \(buyTarget!.name)" : "",
            isPresented: $showBuyConfirm,
            titleVisibility: .visible
        ) {
            if let prop = buyTarget {
                Button("Satın Al — \(formatPrice(prop.price))") { doBuy(prop) }
                Button("İptal", role: .cancel) {}
            }
        } message: {
            if let prop = buyTarget {
                Text("Mevcut nakit: \(formatPrice(game.cash))")
            }
        }
    }

    @ViewBuilder
    private func marketRow(_ prop: Property) -> some View {
        let owned = game.isOwned(prop.id)
        let canAfford = game.cash >= prop.price
        let accent = Color(hex: prop.accentHex)

        GlassCard {
            VStack(alignment: .leading, spacing: Sp.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(prop.category.emoji).font(.system(size: 13))
                            Text(prop.category.label.uppercased())
                                .font(.label_)
                                .foregroundColor(accent)
                        }
                        Text(prop.name)
                            .font(.h4)
                            .foregroundColor(C.text)
                        Text("\(prop.neighborhood) · \(prop.city)")
                            .font(.caption_)
                            .foregroundColor(C.textSub)
                    }

                    Spacer()

                    // Prestige
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= prop.prestige ? "star.fill" : "star")
                                    .font(.system(size: 7))
                                    .foregroundColor(i <= prop.prestige ? C.gold : C.textMuted)
                            }
                        }
                        Text(String(format: "%.1f%%", prop.roiPercent) + " ROI")
                            .font(.caption_)
                            .foregroundColor(C.gold)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatPrice(prop.price))
                            .font(.bodyBold)
                            .foregroundColor(C.text)
                        Text(formatIncome(prop.incomePerDay))
                            .font(.caption_)
                            .foregroundColor(C.green)
                    }

                    Spacer()

                    if owned {
                        Label("Sahipsiniz", systemImage: "checkmark.seal.fill")
                            .font(.btnSm)
                            .foregroundColor(C.green)
                            .padding(.horizontal, Sp.md)
                            .padding(.vertical, Sp.xs)
                            .background(C.green.opacity(0.12))
                            .clipShape(Capsule())
                    } else {
                        Button {
                            buyTarget = prop
                            showBuyConfirm = true
                        } label: {
                            Text(canAfford ? "Satın Al" : "Yetersiz")
                                .font(.btnSm)
                                .foregroundColor(canAfford ? .black : C.textMuted)
                                .padding(.horizontal, Sp.md)
                                .padding(.vertical, Sp.xs)
                                .background(canAfford ? C.primary : C.bgElevated)
                                .clipShape(Capsule())
                        }
                        .disabled(!canAfford)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func chipButton(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.btnSm)
                .foregroundColor(active ? C.primary : C.textSub)
                .padding(.horizontal, Sp.md)
                .padding(.vertical, Sp.xs)
                .background(active ? C.primary.opacity(0.15) : C.bgElevated)
                .overlay(
                    Capsule().stroke(active ? C.primary.opacity(0.5) : Color.clear, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }

    private func doBuy(_ prop: Property) {
        let ok = game.buy(prop)
        let msg = ok ? "\(prop.name) satın alındı!" : "Yetersiz bakiye!"
        withAnimation { toastMsg = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastMsg = nil }
        }
    }
}
