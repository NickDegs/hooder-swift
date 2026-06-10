import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var game: GameStore
    @EnvironmentObject var auth: AuthService
    @State private var nameInput = ""
    @State private var editingName = false
    @State private var showAddCash = false
    @State private var showResetConfirm = false
    @State private var showSignOutConfirm = false

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Sp.md) {
                    // Player card
                    GlassCard {
                        HStack(spacing: Sp.md) {
                            ZStack {
                                Circle()
                                    .fill(C.primary.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(C.primary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                if editingName {
                                    TextField("İsminiz", text: $nameInput)
                                        .font(.h4)
                                        .foregroundStyle(C.text)
                                        .onSubmit { saveName() }
                                        .onAppear { nameInput = game.playerName }
                                } else {
                                    Text(game.playerName)
                                        .font(.h4)
                                        .foregroundStyle(C.text)
                                }
                                Text("Seviye \(game.level) Yatırımcı")
                                    .font(.caption_)
                                    .foregroundStyle(C.textMuted)
                            }

                            Spacer()

                            Button {
                                if editingName { saveName() }
                                else { editingName = true; nameInput = game.playerName }
                            } label: {
                                Image(systemName: editingName ? "checkmark.circle.fill" : "pencil.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(C.primary)
                            }
                        }
                    }

                    // Stats section
                    sectionHeader("İSTATİSTİKLER")
                    GlassCard {
                        VStack(spacing: 0) {
                            statRow("Net Değer",    value: formatPrice(game.netWorth),        accent: C.primary)
                            Divider().background(C.border).padding(.vertical, Sp.xs)
                            statRow("Nakit",         value: formatPrice(game.cash),             accent: C.gold)
                            Divider().background(C.border).padding(.vertical, Sp.xs)
                            statRow("Toplam Mülk",   value: "\(game.owned.count) adet",         accent: C.green)
                            Divider().background(C.border).padding(.vertical, Sp.xs)
                            statRow("Günlük Gelir",  value: formatIncome(game.dailyIncome),     accent: C.green)
                        }
                    }

                    // Account section
                    sectionHeader("HESAP")
                    GlassCard {
                        VStack(spacing: Sp.md) {
                            HStack(spacing: Sp.md) {
                                ZStack {
                                    Circle()
                                        .fill(C.bgElevated)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: auth.userID.hasPrefix("apple_") ? "applelogo" : "globe")
                                        .foregroundStyle(C.primary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(auth.displayName)
                                        .font(.bodyBold)
                                        .foregroundStyle(C.text)
                                    Text(auth.email.isEmpty
                                         ? (auth.userID.hasPrefix("apple_") ? "Apple Hesabı" : "Google Hesabı")
                                         : auth.email)
                                        .font(.caption_)
                                        .foregroundStyle(C.textMuted)
                                }

                                Spacer()

                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(C.green)
                            }

                            Divider().background(C.border)

                            Button {
                                showSignOutConfirm = true
                            } label: {
                                Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                                    .font(.bodyBold)
                                    .foregroundStyle(C.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    // Developer section
                    sectionHeader("GELİŞTİRİCİ")
                    GlassCard {
                        VStack(spacing: Sp.md) {
                            Button {
                                showAddCash = true
                            } label: {
                                Label("Nakit Ekle (Test)", systemImage: "dollarsign.circle")
                                    .font(.bodyBold)
                                    .foregroundStyle(C.gold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Divider().background(C.border)

                            Button {
                                showResetConfirm = true
                            } label: {
                                Label("Oyunu Sıfırla", systemImage: "arrow.counterclockwise")
                                    .font(.bodyBold)
                                    .foregroundStyle(C.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    // About section
                    sectionHeader("HAKKINDA")
                    GlassCard {
                        VStack(spacing: 0) {
                            infoRow("Sürüm", value: appVersion)
                            Divider().background(C.border).padding(.vertical, Sp.xs)
                            infoRow("Harita", value: "Mapbox Maps iOS SDK 11")
                            Divider().background(C.border).padding(.vertical, Sp.xs)
                            infoRow("Geliştirici", value: "realvirtuality.app")
                        }
                    }

                    Spacer(minLength: Sp.x4)
                }
                .padding(.horizontal, Sp.lg)
                .padding(.top, Sp.lg)
            }
            .background(C.bg.ignoresSafeArea())
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog("Nakit Ekle", isPresented: $showAddCash) {
            Button("$100,000 Ekle")    { game.addCash(100_000) }
            Button("$1,000,000 Ekle")  { game.addCash(1_000_000) }
            Button("$10,000,000 Ekle") { game.addCash(10_000_000) }
            Button("İptal", role: .cancel) {}
        }
        .confirmationDialog("Oyunu Sıfırla", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Evet, Sıfırla", role: .destructive) { game.reset() }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Tüm mülkler ve para sıfırlanır. Bu işlem geri alınamaz.")
        }
        .confirmationDialog("Çıkış Yap", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Çıkış Yap", role: .destructive) {
                game.reset()
                auth.signOut()
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Çıkış yaparsan verilerini kaybetmezsin — tekrar giriş yapınca geri yüklenir.")
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.label_)
            .foregroundStyle(C.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Sp.xs)
    }

    @ViewBuilder
    private func statRow(_ label: String, value: String, accent: Color) -> some View {
        HStack {
            Text(label).foregroundStyle(C.textSub)
            Spacer()
            Text(value).foregroundStyle(accent).font(.bodyBold)
        }
    }

    @ViewBuilder
    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(C.textSub)
            Spacer()
            Text(value).foregroundStyle(C.textMuted).font(.caption_)
        }
    }

    private func saveName() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { game.setPlayerName(trimmed) }
        editingName = false
    }
}
