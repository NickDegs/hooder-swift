import SwiftUI

// MARK: - NeighborhoodPanelView

struct NeighborhoodPanelView: View {
    let hood:    HoodGroup
    var onClose: () -> Void

    @EnvironmentObject var game:       GameStore
    @State private var collapsedCats:  Set<PropertyCategory> = []
    @State private var toastMsg:       String?

    private var byCategory: [(PropertyCategory, [Property])] {
        var order: [PropertyCategory] = []
        var map: [PropertyCategory: [Property]] = [:]
        for p in hood.properties {
            if map[p.category] == nil { order.append(p.category); map[p.category] = [] }
            map[p.category]!.append(p)
        }
        return order.map { ($0, map[$0]!) }
    }

    private var ownedCount:   Int { hood.properties.filter { game.isOwned($0.id) }.count }
    private var totalValue:   Int { hood.properties.reduce(0) { $0 + $1.price } }
    private var dailyIncome:  Int { hood.properties.reduce(0) { $0 + $1.incomePerDay } }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {

                // ── Breadcrumb header ─────────────────────────────────────
                VStack(spacing: 0) {
                    // Drag handle
                    Capsule().fill(Color.white.opacity(0.22))
                        .frame(width: 36, height: 4)
                        .padding(.top, 10)

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            // Country
                            HStack(spacing: 5) {
                                Text(hood.flag).font(.system(size: 13))
                                Text(hood.country)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(C.textMuted)
                            }
                            // City
                            HStack(spacing: 5) {
                                Text("›").foregroundStyle(Color.white.opacity(0.3))
                                    .font(.system(size: 13, weight: .medium))
                                Text(hood.city)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.white.opacity(0.72))
                            }
                            .padding(.leading, 4)
                            // Neighborhood
                            HStack(spacing: 5) {
                                Text("›").foregroundStyle(Color.white.opacity(0.3))
                                    .font(.system(size: 14, weight: .medium))
                                Text(hood.neighborhood)
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundStyle(C.text)
                            }
                            .padding(.leading, 4)
                        }
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(C.textMuted)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, Sp.lg)
                    .padding(.top, Sp.md)

                    // Stats strip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            statPill(label: "Mülk",    value: "\(hood.properties.count)",      color: C.text)
                            statPill(label: "Değer",   value: formatPrice(totalValue),           color: C.gold)
                            statPill(label: "Gelir",   value: formatIncome(dailyIncome),         color: C.green)
                            if ownedCount > 0 {
                                statPill(label: "Senin", value: "\(ownedCount) mülk", color: C.green)
                            }
                        }
                        .padding(.horizontal, Sp.lg)
                    }
                    .padding(.vertical, 10)
                }
                .background(.ultraThinMaterial)
                .overlay(alignment: .bottom) {
                    Divider().opacity(0.3)
                }

                // ── Property list grouped by category ─────────────────────
                ScrollView {
                    LazyVStack(spacing: 10, pinnedViews: []) {
                        ForEach(byCategory, id: \.0) { cat, props in
                            categorySection(cat: cat, props: props)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .padding(.bottom, 28)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(C.specular, lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.5), radius: 28, y: -6)
            .padding(.horizontal, 0)
            .ignoresSafeArea(edges: .bottom)

            // Toast
            if let msg = toastMsg {
                Text(msg)
                    .font(.bodyBold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(msg.hasPrefix("✓") ? C.green : Color(hex: "#ff453a"))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
                    .padding(.bottom, 100)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: toastMsg)
    }

    @ViewBuilder
    private func categorySection(cat: PropertyCategory, props: [Property]) -> some View {
        let isOpen     = !collapsedCats.contains(cat)
        let ownedInCat = props.filter { game.isOwned($0.id) }.count
        let accent     = Color(hex: cat.accentHex)

        VStack(spacing: 6) {
            // Category header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isOpen { collapsedCats.insert(cat) }
                    else      { collapsedCats.remove(cat) }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(cat.emoji).font(.system(size: 15))
                    Text(cat.label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isOpen ? accent : C.text)
                    Spacer()
                    if ownedInCat > 0 {
                        Text("✓\(ownedInCat)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(C.green)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(C.green.opacity(0.15))
                            .overlay(
                                Capsule().stroke(C.green.opacity(0.3), lineWidth: 0.5)
                            )
                            .clipShape(Capsule())
                    }
                    Text("\(props.count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(C.textMuted)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(C.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isOpen ? accent.opacity(0.1) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isOpen ? accent.opacity(0.35) : Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            // Property cards
            if isOpen {
                ForEach(props) { prop in
                    propertyCard(prop)
                }
            }
        }
    }

    @ViewBuilder
    private func propertyCard(_ prop: Property) -> some View {
        let owned     = game.isOwned(prop.id)
        let canAfford = game.cash >= prop.price
        let accent    = Color(hex: prop.accentHex)

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    // Name
                    HStack(spacing: 4) {
                        Text(prop.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(C.text)
                            .lineLimit(1)
                        if owned { Text("✓").font(.system(size: 10)).foregroundStyle(C.green) }
                    }
                    // Address
                    if !prop.address.isEmpty {
                        Text(prop.address)
                            .font(.system(size: 9))
                            .foregroundStyle(C.textMuted)
                            .lineLimit(1)
                    }
                    // Stats
                    HStack(spacing: 5) {
                        miniStat(label: "FİYAT",   value: formatPrice(prop.price),                   color: C.text)
                        miniStat(label: "GÜNLÜK",  value: formatIncome(prop.incomePerDay),            color: C.green)
                        miniStat(label: "ROI",     value: String(format: "%.1f%%", prop.roiPercent),  color: C.gold)
                        miniStat(label: "PRESTİJ", value: String(repeating: "★", count: prop.prestige), color: C.purple)
                    }
                }

                Spacer()

                // Buy / Sell
                if owned {
                    Button { doSell(prop) } label: {
                        Text("Sat").font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: "#ff453a"))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Color(hex: "#ff453a").opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color(hex: "#ff453a").opacity(0.3), lineWidth: 0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { doBuy(prop) } label: {
                        Text(canAfford ? "Al" : "🔒")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(canAfford ? accent : C.textMuted)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(canAfford ? accent.opacity(0.12) : Color.white.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(canAfford ? accent.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAfford)
                    .opacity(canAfford ? 1 : 0.65)
                }
            }
            .padding(.horizontal, 13)
            .padding(.top, 11)

            // Description
            Text(prop.description)
                .font(.system(size: 9))
                .foregroundStyle(C.textMuted)
                .lineLimit(2)
                .padding(.horizontal, 13)
                .padding(.top, 6)
                .padding(.bottom, 11)
        }
        .background(owned ? C.green.opacity(0.07) : Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(owned ? C.green.opacity(0.22) : Color.white.opacity(0.09), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func miniStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label).font(.system(size: 7, weight: .bold)).foregroundStyle(C.textMuted)
            Text(value).font(.system(size: 9, weight: .bold)).foregroundStyle(color)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private func statPill(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 9, weight: .semibold)).foregroundStyle(C.textMuted)
            Text(value).font(.system(size: 10, weight: .bold)).foregroundStyle(color)
        }
        .padding(.horizontal, 10).padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        .clipShape(Capsule())
    }

    private func doBuy(_ prop: Property) {
        let ok = game.buy(prop)
        showToast(ok ? "✓ \(prop.name) satın alındı!" : "Yetersiz bakiye!")
    }

    private func doSell(_ prop: Property) {
        game.sell(prop.id)
        showToast("\(prop.name) satıldı")
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMsg = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { toastMsg = nil } }
    }
}
