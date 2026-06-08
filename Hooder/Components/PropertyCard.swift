import SwiftUI

struct PropertyCard: View {
    let property: Property
    @EnvironmentObject var game: GameStore

    var accent: Color { Color(hex: property.accentHex) }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Sp.sm) {
                HStack(alignment: .top) {
                    // Category badge
                    HStack(spacing: 4) {
                        Text(property.category.emoji)
                            .font(.system(size: 14))
                        Text(property.category.label.uppercased())
                            .font(.label_)
                            .foregroundColor(accent)
                    }
                    .padding(.horizontal, Sp.sm)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.15))
                    .clipShape(Capsule())

                    Spacer()

                    // Prestige stars
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= property.prestige ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundColor(i <= property.prestige ? C.gold : C.textMuted)
                        }
                    }
                }

                Text(property.name)
                    .font(.h4)
                    .foregroundColor(C.text)
                    .lineLimit(2)

                Text("\(property.neighborhood) · \(property.city)")
                    .font(.caption_)
                    .foregroundColor(C.textSub)

                Divider().background(C.border)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FİYAT")
                            .font(.label_)
                            .foregroundColor(C.textMuted)
                        Text(formatPrice(property.price))
                            .font(.bodyBold)
                            .foregroundColor(C.text)
                    }
                    Spacer()
                    VStack(alignment: .center, spacing: 2) {
                        Text("GELİR")
                            .font(.label_)
                            .foregroundColor(C.textMuted)
                        Text(formatIncome(property.incomePerDay))
                            .font(.bodyBold)
                            .foregroundColor(C.green)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ROI")
                            .font(.label_)
                            .foregroundColor(C.textMuted)
                        Text(String(format: "%.1f%%", property.roiPercent))
                            .font(.bodyBold)
                            .foregroundColor(C.gold)
                    }
                }
            }
        }
    }
}

struct OwnedPropertyCard: View {
    let op: OwnedProperty
    @EnvironmentObject var game: GameStore
    var onSell: (() -> Void)?

    var accent: Color { Color(hex: op.accentHex) }
    var sellPrice: Int { Int(Double(op.price) * 1.15) }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Sp.sm) {
                HStack(alignment: .top) {
                    HStack(spacing: 4) {
                        Text(op.category.emoji).font(.system(size: 14))
                        Text(op.category.label.uppercased())
                            .font(.label_)
                            .foregroundColor(accent)
                    }
                    .padding(.horizontal, Sp.sm)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.15))
                    .clipShape(Capsule())

                    Spacer()

                    Text(op.city)
                        .font(.caption_)
                        .foregroundColor(C.textSub)
                }

                Text(op.name)
                    .font(.h4)
                    .foregroundColor(C.text)
                    .lineLimit(2)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SATIN ALINAN")
                            .font(.label_)
                            .foregroundColor(C.textMuted)
                        Text(formatPrice(op.price))
                            .font(.bodyBold)
                            .foregroundColor(C.text)
                    }
                    Spacer()
                    VStack(alignment: .center, spacing: 2) {
                        Text("GÜNLÜK")
                            .font(.label_)
                            .foregroundColor(C.textMuted)
                        Text(formatIncome(op.incomePerDay))
                            .font(.bodyBold)
                            .foregroundColor(C.green)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("TOPLAM KAZANÇ")
                            .font(.label_)
                            .foregroundColor(C.textMuted)
                        Text(formatPrice(op.totalEarned))
                            .font(.bodyBold)
                            .foregroundColor(C.gold)
                    }
                }

                Button {
                    onSell?()
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.right.circle.fill")
                        Text("SAT — \(formatPrice(sellPrice))")
                            .font(.btnSm)
                    }
                    .foregroundColor(C.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Sp.sm)
                    .background(C.green.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: R.sm)
                            .stroke(C.green.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: R.sm))
                }
            }
        }
    }
}
