import SwiftUI

private struct LeaderEntry: Identifiable {
    let id: Int
    let name: String
    let netWorth: Int
    let ownedCount: Int
    let flag: String
    let isPlayer: Bool
}

private func buildLeaderboard(player: GameStore) -> [LeaderEntry] {
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

    var leaders: [LeaderEntry] { buildLeaderboard(player: game) }

    var playerRank: Int {
        (leaders.firstIndex { $0.isPlayer } ?? leaders.count - 1) + 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Sp.md) {
                    // Player rank card
                    playerRankCard

                    // Leaderboard
                    VStack(spacing: Sp.sm) {
                        ForEach(Array(leaders.enumerated()), id: \.element.id) { rank, entry in
                            rankRow(rank: rank + 1, entry: entry)
                        }
                    }
                    .padding(.horizontal, Sp.lg)

                    Spacer(minLength: 100)
                }
                .padding(.top, Sp.lg)
            }
            .background(C.bg.ignoresSafeArea())
            .navigationTitle("Sıralama")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var playerRankCard: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sıralaman")
                        .font(.label_)
                        .foregroundColor(C.textMuted)
                    Text("#\(playerRank)")
                        .font(.display)
                        .foregroundColor(C.primary)
                    Text("/ \(leaders.count) oyuncu")
                        .font(.caption_)
                        .foregroundColor(C.textSub)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Sp.sm) {
                    StatBadge(label: "Net Değer", value: formatPrice(game.netWorth), accent: C.gold)
                        .frame(maxWidth: 120)
                    StatBadge(label: "Mülk", value: "\(game.owned.count)", accent: C.green)
                        .frame(maxWidth: 120)
                }
            }
        }
        .padding(.horizontal, Sp.lg)
    }

    @ViewBuilder
    private func rankRow(rank: Int, entry: LeaderEntry) -> some View {
        let isTop3 = rank <= 3
        let medalsIcon = ["🥇", "🥈", "🥉"]

        HStack(spacing: Sp.md) {
            // Rank
            ZStack {
                if rank <= 3 {
                    Text(medalsIcon[rank - 1])
                        .font(.system(size: 22))
                } else {
                    Text("\(rank)")
                        .font(.bodyBold)
                        .foregroundColor(entry.isPlayer ? C.primary : C.textSub)
                        .frame(width: 28)
                }
            }
            .frame(width: 32)

            Text(entry.flag).font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(entry.isPlayer ? .bodyBold : .body_)
                    .foregroundColor(entry.isPlayer ? C.primary : C.text)
                Text("\(entry.ownedCount) mülk")
                    .font(.caption_)
                    .foregroundColor(C.textMuted)
            }

            Spacer()

            Text(formatPrice(entry.netWorth))
                .font(.bodyBold)
                .foregroundColor(isTop3 ? C.gold : (entry.isPlayer ? C.primary : C.textSub))
        }
        .padding(.horizontal, Sp.md)
        .padding(.vertical, Sp.sm)
        .background(entry.isPlayer ? C.primary.opacity(0.08) : C.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: R.md)
                .stroke(entry.isPlayer ? C.primary.opacity(0.3) : C.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: R.md))
    }
}
