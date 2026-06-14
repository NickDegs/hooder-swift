import SwiftUI

// MARK: - PlaceClaimPanelView

struct PlaceClaimPanelView: View {
    let info:    PlaceClaimInfo
    var onClose: () -> Void

    @EnvironmentObject var game: GameStore
    @State private var toastMsg: String?

    private var pid:       String { placeId(lat: info.lat, lng: info.lng) }
    private var claimed:   Bool   { game.isPlaceClaimed(pid) }
    private var price:     Int    { generatePlacePrice(lat: info.lat, lng: info.lng, placeType: info.placeType) }
    private var income:    Int    { generatePlaceIncome(price: price) }
    private var canAfford: Bool   { game.cash >= price }
    private var annualYield: Double { Double(income) * 365 / Double(price) * 100 }

    private var emoji:     String { placeTypeEmoji(info.placeType) }
    private var typeLabel: String { placeTypeLabel(info.placeType) }
    private var accent:    Color  { Color(hex: placeTypeAccent(info.placeType)) }

    private var displayName: String {
        info.name.isEmpty
            ? "\(typeLabel) — \(String(format: "%.3f", info.lat)), \(String(format: "%.3f", info.lng))"
            : info.name
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────────────
                VStack(spacing: 0) {
                    Capsule().fill(Color.white.opacity(0.22))
                        .frame(width: 36, height: 4)
                        .padding(.top, 10)

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            // Type badge + claimed badge
                            HStack(spacing: 6) {
                                HStack(spacing: 4) {
                                    Text(emoji).font(.system(size: 11))
                                    Text(typeLabel)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(accent)
                                }
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(accent.opacity(0.14))
                                .overlay(Capsule().stroke(accent.opacity(0.4), lineWidth: 0.5))
                                .clipShape(Capsule())

                                if claimed {
                                    HStack(spacing: 3) {
                                        Text("✓").font(.system(size: 9))
                                        Text("Senin").font(.system(size: 9, weight: .bold))
                                    }
                                    .foregroundStyle(C.green)
                                    .padding(.horizontal, 8).padding(.vertical, 2)
                                    .background(C.green.opacity(0.14))
                                    .overlay(Capsule().stroke(C.green.opacity(0.35), lineWidth: 0.5))
                                    .clipShape(Capsule())
                                }
                            }
                            // Name
                            Text(displayName)
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(C.text)
                                .lineLimit(2)
                            // Address
                            if !info.address.isEmpty {
                                Text(info.address)
                                    .font(.system(size: 11))
                                    .foregroundStyle(C.textSub)
                            }
                            // Coords
                            Text(String(format: "%.5f, %.5f", info.lat, info.lng))
                                .font(.system(size: 9))
                                .foregroundStyle(C.textMuted)
                        }

                        Spacer()

                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(C.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Sp.lg)
                    .padding(.top, Sp.md)
                    .padding(.bottom, Sp.md)
                }
                .background(.ultraThinMaterial)
                .overlay(alignment: .bottom) { Divider().opacity(0.3) }

                // ── Stats ─────────────────────────────────────────────────
                HStack(spacing: 10) {
                    statCard(label: "FİYAT",        value: formatPrice(price),                       color: C.text)
                    statCard(label: "GÜNLÜK GELİR", value: formatIncome(income),                     color: C.green)
                    statCard(label: "YILLIK GETİRİ",value: String(format: "%.1f%%", annualYield),    color: C.gold)
                }
                .padding(.horizontal, Sp.lg)
                .padding(.vertical, Sp.md)

                Spacer()

                // ── Action button ─────────────────────────────────────────
                if claimed {
                    Button(action: doUnclaim) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.uturn.left")
                            Text("Sat (+%15 kâr)")
                                .font(.btnLg)
                        }
                        .foregroundStyle(Color(hex: "#ff453a"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Sp.lg)
                        .background(Color(hex: "#ff453a").opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: R.lg, style: .continuous)
                                .stroke(Color(hex: "#ff453a").opacity(0.4), lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: R.lg, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Sp.lg)
                    .padding(.bottom, Sp.lg)
                } else {
                    Button(action: doClaim) {
                        HStack(spacing: 8) {
                            Image(systemName: canAfford ? "cart.fill" : "lock.fill")
                            Text(canAfford
                                 ? "\(emoji) Satın Al — \(formatPrice(price))"
                                 : "Yetersiz bakiye (\(formatPrice(price)))")
                                .font(.btnLg)
                        }
                        .foregroundStyle(canAfford ? .black : C.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Sp.lg)
                        .background(canAfford ? accent : Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: R.lg, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAfford)
                    .opacity(canAfford ? 1 : 0.7)
                    .padding(.horizontal, Sp.lg)
                    .padding(.bottom, Sp.lg)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(C.specular, lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.5), radius: 28, y: -6)
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
        .frame(height: UIScreen.main.bounds.height * 0.5)
    }

    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(C.textMuted).lineLimit(1)
            Text(value).font(.system(size: 13, weight: .black))
                .foregroundStyle(color).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func doClaim() {
        let place = ClaimedPlace(
            id: pid, name: displayName, address: info.address,
            placeType: info.placeType, lat: info.lat, lng: info.lng,
            price: price, incomePerDay: income, purchasedAt: Date()
        )
        let ok = game.claimPlace(place)
        showToast(ok ? "✓ \(displayName) satın alındı!" : "Yetersiz bakiye!")
    }

    private func doUnclaim() {
        game.unclaimPlace(pid)
        showToast("\(displayName) satıldı")
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMsg = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { toastMsg = nil } }
    }
}
