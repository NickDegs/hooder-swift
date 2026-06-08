import Foundation
import Combine
import CoreLocation

// MARK: - Owned Property

struct OwnedProperty: Identifiable, Hashable {
    let id:          String
    let property:    Property
    var purchasedAt: Date
    var totalEarned: Int

    // Forward commonly used fields
    var name:         String { property.name }
    var category:     PropertyCategory { property.category }
    var price:        Int { property.price }
    var incomePerDay: Int { property.incomePerDay }
    var prestige:     Int { property.prestige }
    var city:         String { property.city }
    var country:      String { property.country }
    var neighborhood: String { property.neighborhood }
    var accentHex:    String { property.accentHex }
    var thumbURL:     URL?   { property.thumbURL }
    var coordinate:   CLLocationCoordinate2D { property.coordinate }
    var description:  String { property.description }
    var roiPercent:   Double { property.roiPercent }
}

// MARK: - GameStore

final class GameStore: ObservableObject {

    // Player
    @Published var playerName:  String = "Player"
    @Published var cash:        Int    = 50_000
    @Published var netWorth:    Int    = 50_000
    @Published var level:       Int    = 1
    @Published var xp:          Int    = 0

    // Properties
    @Published var owned:       [OwnedProperty] = []
    @Published var dailyIncome: Int    = 0
    @Published var lastCollect: Date   = Date()

    // MARK: Computed

    var pendingIncome: Int {
        let hours = min(Date().timeIntervalSince(lastCollect) / 3_600, 24)
        return Int(owned.reduce(0.0) { $0 + Double($1.incomePerDay) * hours / 24 })
    }

    func isOwned(_ id: String) -> Bool {
        owned.contains { $0.id == id }
    }

    // MARK: Actions

    func setPlayerName(_ name: String) {
        playerName = name
    }

    @discardableResult
    func buy(_ property: Property) -> Bool {
        guard cash >= property.price, !isOwned(property.id) else { return false }
        let op = OwnedProperty(id: property.id, property: property,
                               purchasedAt: Date(), totalEarned: 0)
        owned.append(op)
        cash    -= property.price
        dailyIncome = owned.reduce(0) { $0 + $1.incomePerDay }
        netWorth = cash + owned.reduce(0) { $0 + $1.price }
        return true
    }

    func sell(_ id: String) {
        guard let idx = owned.firstIndex(where: { $0.id == id }) else { return }
        let prop = owned[idx]
        let sellPrice = Int(Double(prop.price) * 1.15)
        owned.remove(at: idx)
        cash    += sellPrice
        dailyIncome = owned.reduce(0) { $0 + $1.incomePerDay }
        netWorth = cash + owned.reduce(0) { $0 + $1.price }
    }

    @discardableResult
    func collectIncome() -> Int {
        let hours   = min(Date().timeIntervalSince(lastCollect) / 3_600, 24)
        let earned  = Int(owned.reduce(0.0) { $0 + Double($1.incomePerDay) * hours / 24 })
        guard earned > 0 else { return 0 }
        owned = owned.map {
            var p = $0
            let share = Int(Double($0.incomePerDay) * hours / 24)
            p.totalEarned += share
            return p
        }
        cash        += earned
        lastCollect  = Date()
        netWorth     = cash + owned.reduce(0) { $0 + $1.price }
        return earned
    }

    func addCash(_ amount: Int) {
        cash     += amount
        netWorth += amount
    }
}
