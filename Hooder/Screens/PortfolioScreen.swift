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
                    // Summary cards
                    HStack(spacing: Sp.sm) {
                        StatBadge(label: "Net Değer",   value: formatPrice(game.netWorth),  accent: C.primary)
                        StatBadge(label: "Nakit",        value: formatPrice(game.cash),       accent: C.gold)
                        StatBadge(label: "Günlük Gelir", value: formatIncome(game.dailyIncome), accent: C.green)
                    }
                    .padding(.horizontal, Sp.lg)

                    // Collect income button
                    Button {
                        let earned = game.collectIncome()
                        if earned > 0 {
                            collectedAmount = earned
                            withAnimation { showCollectToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation { showCollectToast = false }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Geliri Topla")
                                    .font(.btnMd)
                                Text(formatPrice(game.pendingIncome) + " bekliyor")
                                    .font(.caption_)
                                    .opacity(0.7)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption_)
                        }
                        .foregroundColor(game.pendingIncome > 0 ? .black : C.textMuted)
                        .padding(.horizontal, Sp.lg)
                        .padding(.vertical, Sp.md)
                        .background(game.pendingIncome > 0 ? C.green : C.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: R.lg))
                    }
                    .padding(.horizontal, Sp.lg)

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

                    Spacer(minLength: 100)
                }
                .padding(.top, Sp.lg)
            }
            .background(C.bg.ignoresSafeArea())
            .navigationTitle("Portföyüm")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottom) {
                if showCollectToast {
                    Text("+\(formatPrice(collectedAmount)) toplandı!")
                        .font(.bodyBold)
                        .foregroundColor(.black)
                        .padding(.horizontal, Sp.lg)
                        .padding(.vertical, Sp.md)
                        .background(C.green)
                        .clipShape(Capsule())
                        .padding(.bottom, 100)
                        .transition(.opacity.combined(with: .scale))
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
            Image(systemName: "building.2")
                .font(.system(size: 56))
                .foregroundColor(C.textMuted)
            Text("Henüz mülk yok")
                .font(.h3)
                .foregroundColor(C.textSub)
            Text("Piyasa ekranından mülk satın alarak\nportföyünüzü oluşturun.")
                .font(.body_)
                .foregroundColor(C.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Sp.x4)
    }
}
