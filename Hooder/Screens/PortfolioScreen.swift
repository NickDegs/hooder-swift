import SwiftUI

struct PortfolioScreen: View {
    @EnvironmentObject var game: GameStore
    @State private var showCollectToast = false
    @State private var collectedAmount = 0
    @State private var sellTarget: OwnedProperty?
    @State private var showSellConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Sp.lg) {
                    // Summary stat badges
                    HStack(spacing: Sp.sm) {
                        StatBadge(label: "Net Değer",    value: formatPrice(game.netWorth),     accent: C.primary)
                        StatBadge(label: "Nakit",         value: formatPrice(game.cash),          accent: C.gold)
                        StatBadge(label: "Günlük Gelir",  value: formatIncome(game.dailyIncome),  accent: C.green)
                    }
                    .padding(.horizontal, Sp.lg)

                    // Collect income button
                    Button {
                        let earned = game.collectIncome()
                        if earned > 0 {
                            collectedAmount = earned
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                showCollectToast = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation { showCollectToast = false }
                            }
                        }
                    } label: {
                        HStack(spacing: Sp.md) {
                            ZStack {
                                Circle()
                                    .fill(game.pendingIncome > 0 ? C.green.opacity(0.2) : C.bgElevated)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(game.pendingIncome > 0 ? C.green : C.textMuted)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Geliri Topla")
                                    .font(.btnMd)
                                    .foregroundStyle(game.pendingIncome > 0 ? C.text : C.textMuted)
                                Text(formatPrice(game.pendingIncome) + " bekliyor")
                                    .font(.caption_)
                                    .foregroundStyle(game.pendingIncome > 0 ? C.green : C.textMuted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(game.pendingIncome > 0 ? C.textSub : C.textMuted)
                        }
                        .padding(.horizontal, Sp.lg)
                        .padding(.vertical, Sp.md)
                        .background {
                            RoundedRectangle(cornerRadius: R.lg, style: .continuous)
                                .fill(game.pendingIncome > 0 ? C.green.opacity(0.1) : Color.clear)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: R.lg, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: R.lg, style: .continuous)
                                        .stroke(game.pendingIncome > 0 ? C.green.opacity(0.3) : C.border, lineWidth: 0.5)
                                }
                        }
                    }
                    .padding(.horizontal, Sp.lg)
                    .buttonStyle(.plain)

                    if game.owned.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: Sp.md) {
                            ForEach(game.owned) { op in
                                OwnedPropertyCard(op: op) {
                                    sellTarget = op
                                    showSellConfirm = true
                                }
                                .padding(.horizontal, Sp.lg)
                            }
                        }
                    }

                    Spacer(minLength: Sp.x4)
                }
                .padding(.top, Sp.lg)
            }
            .background(C.bg.ignoresSafeArea())
            .navigationTitle("Portföyüm")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottom) {
                if showCollectToast {
                    Label("+\(formatPrice(collectedAmount)) toplandı!", systemImage: "sparkles")
                        .font(.bodyBold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, Sp.lg)
                        .padding(.vertical, Sp.md)
                        .background(C.green, in: Capsule())
                        .padding(.bottom, Sp.x3)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
        }
        .confirmationDialog(
            sellTarget != nil ? "Sat: \(sellTarget!.name)" : "",
            isPresented: $showSellConfirm,
            titleVisibility: .visible
        ) {
            if let op = sellTarget {
                let sellPrice = Int(Double(op.price) * 1.15)
                Button("Sat — \(formatPrice(sellPrice))", role: .destructive) {
                    game.sell(op.id)
                }
                Button("İptal", role: .cancel) {}
            }
        } message: {
            if let op = sellTarget {
                Text("Satış fiyatı orijinalin %15 üzerinde: \(formatPrice(Int(Double(op.price) * 1.15)))")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Sp.lg) {
            ZStack {
                Circle()
                    .fill(C.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "building.2")
                    .font(.system(size: 44))
                    .foregroundStyle(C.textMuted)
            }
            VStack(spacing: Sp.sm) {
                Text("Henüz mülk yok")
                    .font(.h3)
                    .foregroundStyle(C.textSub)
                Text("Piyasa ekranından mülk satın alarak\nportföyünüzü oluşturun.")
                    .font(.body_)
                    .foregroundStyle(C.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Sp.x4)
    }
}
