import SwiftUI

fileprivate struct LeaderEntry: Identifiable {
    let id: Int
    let name: String
    let netWorth: Int
    let ownedCount: Int
    let flag: String
    let isPlayer: Bool
}

fileprivate func buildLeaderboard(player: GameStore) -> [LeaderEntry] {
    let bots: [(String, Int, Int, String)] = [
        ("Sheikh Al-Rashid",  890_000_000, 47, "🇦🇪"),
        ("Victoria Blackwood",750_000_000, 39, "🇬🇧"),
        ("Hiroshi Tanaka",    620_000_000, 33, "🇯🇵"),
        ("Isabella Morel",    480_000_000, 28, "🇫🇷"),
        ("Magnus Eriksson",   310_000_000, 22, "🇸🇪"),
        ("Layla Hassan",      250_000_000, 19, "🇸🇦"),
        ("Carlos Mendes",     190_000_000, 15, "🇧🇷"),
        ("Yuki Nakamura",     145_000_000, 12, "🇯🇵"),
        ("Sophie Müller",      98_000_000,  9, "🇩🇪"),
        ("Ali Karimov",        72_000_000,  7, "🇦🇿"),
    ]

    var entries: [LeaderEntry] = bots.enumerated().map { (i, bot) in
        LeaderEntry(id: i, name: bot.0, netWorth: bot.1, ownedCount: bot.2, flag: bot.3, isPlayer: false)
    }

    let playerEntry = LeaderEntry(
        id: 99,
        name: player.playerName + " (Sen)",
        netWorth: player.netWorth,
        ownedCount: player.owned.count,
        flag: "🏠",
        isPlayer: true
    )
    entries.append(playerEntry)
    entries.sort { $0.netWorth > $1.netWorth }
    return entries
}

struct RankingsScreen: View {
    @EnvironmentObject var game: GameStore

    fileprivate var leaders: [LeaderEntry] { buildLeaderboard(player: game) }

    var playerRank: Int {
        (leaders.firstIndex { $0.isPlayer } ?? leaders.count - 1) + 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Sp.md) {
                    // Player rank card
                    playerRankCard
                        .padding(.horizontal, Sp.lg)

                    // Leaderboard
                    VStack(spacing: Sp.sm) {
                        ForEach(Array(leaders.enumerated()), id: \.element.id) { rank, entry in
                            rankRow(rank: rank + 1, entry: entry)
                        }
                    }
                    .padding(.horizontal, Sp.lg)

                    Spacer(minLength: Sp.x4)
                }
                .padding(.top, Sp.lg)
            }
            .background(Color.clear.ignoresSafeArea())
            .navigationTitle("Sıralama")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var playerRankCard: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sıralaman")
                        .font(.label_)
                        .foregroundStyle(C.textMuted)
                    Text("#\(playerRank)")
                        .font(.display)
                        .foregroundStyle(C.primary)
                    Text("/ \(leaders.count) oyuncu")
                        .font(.caption_)
                        .foregroundStyle(C.textSub)
                }

                Spacer()

                VStack(spacing: Sp.sm) {
                    StatBadge(label: "Net Değer", value: formatPrice(game.netWorth), accent: C.gold)
                        .frame(maxWidth: 130)
                    StatBadge(label: "Mülk", value: "\(game.owned.count)", accent: C.green)
                        .frame(maxWidth: 130)
                }
            }
        }
    }

    @ViewBuilder
    private func rankRow(rank: Int, entry: LeaderEntry) -> some View {
        let medals = ["🥇", "🥈", "🥉"]

        HStack(spacing: Sp.md) {
            // Rank badge
            ZStack {
                if rank <= 3 {
                    Text(medals[rank - 1])
                        .font(.system(size: 22))
                } else {
                    Text("\(rank)")
                        .font(.bodyBold)
                        .foregroundStyle(entry.isPlayer ? C.primary : C.textSub)
                        .frame(width: 28)
                }
            }
            .frame(width: 32)

            Text(entry.flag).font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(entry.isPlayer ? .bodyBold : .body_)
                    .foregroundStyle(entry.isPlayer ? C.primary : C.text)
                Text("\(entry.ownedCount) mülk")
                    .font(.caption_)
                    .foregroundStyle(C.textMuted)
            }

            Spacer()

            Text(formatPrice(entry.netWorth))
                .font(.bodyBold)
                .foregroundStyle(rank <= 3 ? C.gold : (entry.isPlayer ? C.primary : C.textSub))
        }
        .padding(.horizontal, Sp.md)
        .padding(.vertical, Sp.sm + 2)
        .background {
            RoundedRectangle(cornerRadius: R.md, style: .continuous)
                .fill(entry.isPlayer ? C.primary.opacity(0.08) : Color.clear)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: R.md, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: R.md, style: .continuous)
                        .stroke(entry.isPlayer ? C.primary.opacity(0.3) : C.border, lineWidth: 0.5)
                }
        }
    }
}
