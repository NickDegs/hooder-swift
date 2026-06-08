import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var game: GameStore
    @State private var nameInput = ""
    @State private var editingName = false
    @State private var showAddCash = false
    @State private var showResetConfirm = false

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                // Player section
                Section {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(C.primary)

                        VStack(alignment: .leading, spacing: 4) {
                            if editingName {
                                TextField("İsminiz", text: $nameInput, onCommit: saveName)
                                    .font(.h4)
                                    .foregroundColor(C.text)
                                    .onAppear { nameInput = game.playerName }
                            } else {
                                Text(game.playerName)
                                    .font(.h4)
                                    .foregroundColor(C.text)
                            }
                            Text("Seviye \(game.level) Yatırımcı")
                                .font(.caption_)
                                .foregroundColor(C.textMuted)
                        }

                        Spacer()

                        Button {
                            if editingName { saveName() }
                            else { editingName = true; nameInput = game.playerName }
                        } label: {
                            Image(systemName: editingName ? "checkmark.circle.fill" : "pencil")
                                .foregroundColor(C.primary)
                        }
                    }
                    .listRowBackground(C.bgCard)
                } header: {
                    Text("OYUNCu").font(.label_).foregroundColor(C.textMuted)
                }

                // Stats section
                Section {
                    statRow("Net Değer", value: formatPrice(game.netWorth), accent: C.primary)
                    statRow("Nakit", value: formatPrice(game.cash), accent: C.gold)
                    statRow("Toplam Mülk", value: "\(game.owned.count)", accent: C.green)
                    statRow("Günlük Gelir", value: formatIncome(game.dailyIncome), accent: C.green)
                } header: {
                    Text("İSTATİSTİKLER").font(.label_).foregroundColor(C.textMuted)
                }
                .listRowBackground(C.bgCard)

                // Cheats section
                Section {
                    Button {
                        showAddCash = true
                    } label: {
                        Label("Nakit Ekle (Test)", systemImage: "dollarsign.circle")
                            .foregroundColor(C.gold)
                    }
                    .listRowBackground(C.bgCard)

                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Oyunu Sıfırla", systemImage: "arrow.counterclockwise")
                    }
                    .listRowBackground(C.bgCard)
                } header: {
                    Text("GELİŞTİRİCİ").font(.label_).foregroundColor(C.textMuted)
                }

                // About section
                Section {
                    HStack {
                        Text("Sürüm")
                            .foregroundColor(C.textSub)
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(C.textMuted)
                    }
                    .listRowBackground(C.bgCard)

                    HStack {
                        Text("Harita")
                            .foregroundColor(C.textSub)
                        Spacer()
                        Text("Mapbox Maps iOS SDK 11")
                            .foregroundColor(C.textMuted)
                    }
                    .listRowBackground(C.bgCard)
                } header: {
                    Text("HAKKINDA").font(.label_).foregroundColor(C.textMuted)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(C.bg.ignoresSafeArea())
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog("Nakit Ekle", isPresented: $showAddCash) {
            Button("$100,000 Ekle")   { game.addCash(100_000) }
            Button("$1,000,000 Ekle") { game.addCash(1_000_000) }
            Button("$10,000,000 Ekle") { game.addCash(10_000_000) }
            Button("İptal", role: .cancel) {}
        }
        .confirmationDialog("Oyunu Sıfırla", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Evet, Sıfırla", role: .destructive) { resetGame() }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Tüm mülkler ve para sıfırlanır. Bu işlem geri alınamaz.")
        }
    }

    @ViewBuilder
    private func statRow(_ label: String, value: String, accent: Color) -> some View {
        HStack {
            Text(label).foregroundColor(C.textSub)
            Spacer()
            Text(value).foregroundColor(accent).font(.bodyBold)
        }
    }

    private func saveName() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { game.setPlayerName(trimmed) }
        editingName = false
    }

    private func resetGame() {
        game.cash        = 50_000
        game.netWorth    = 50_000
        game.owned       = []
        game.dailyIncome = 0
        game.level       = 1
        game.xp          = 0
        game.lastCollect = Date()
    }
}
