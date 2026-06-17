import Foundation
import Combine
import CoreLocation

// MARK: - OwnedProperty

struct OwnedProperty: Identifiable, Hashable {
    let id:          String
    let property:    Property
    var purchasedAt: Date
    var totalEarned: Int

    var name:         String { property.name }
    var category:     PropertyCategory { property.category }
    var price:        Int { property.price }
    var incomePerDay: Int { property.incomePerDay }
    var prestige:     Int { property.prestige }
    var city:         String { property.city }
    var country:      String { property.country }
    var neighborhood: String { property.neighborhood }
    var accentHex:    String { property.accentHex }
    var coordinate:   CLLocationCoordinate2D { property.coordinate }
    var description:  String { property.description }
    var roiPercent:   Double { property.roiPercent }
}

// MARK: - GameStore

final class GameStore: ObservableObject {

    @Published var playerName:  String          = "Oyuncu"
    @Published var cash:        Int             = 5_000_000
    @Published var netWorth:    Int             = 5_000_000
    @Published var level:       Int             = 1
    @Published var xp:          Int             = 0
    @Published var owned:       [OwnedProperty] = []
    @Published var claimed:     [ClaimedPlace]  = []
    @Published var dailyIncome: Int             = 0
    @Published var lastCollect: Date            = Date()

    var pendingIncome: Int {
        let hours = min(Date().timeIntervalSince(lastCollect) / 3_600, 24)
        let fromOwned   = owned.reduce(0.0) { $0 + Double($1.incomePerDay) * hours / 24 }
        let fromClaimed = claimed.reduce(0.0) { $0 + Double($1.incomePerDay) * hours / 24 }
        return Int(fromOwned + fromClaimed)
    }

    func isOwned(_ id: String) -> Bool { owned.contains { $0.id == id } }
    func isPlaceClaimed(_ id: String) -> Bool { claimed.contains { $0.id == id } }

    // MARK: - Actions

    func setPlayerName(_ name: String) { playerName = name; save() }

    @discardableResult
    func buy(_ property: Property) -> Bool {
        guard cash >= property.price, !isOwned(property.id) else { return false }
        let op = OwnedProperty(id: property.id, property: property, purchasedAt: Date(), totalEarned: 0)
        owned.append(op)
        cash        -= property.price
        dailyIncome  = owned.reduce(0) { $0 + $1.incomePerDay }
        netWorth     = cash + owned.reduce(0) { $0 + $1.price }
        save()
        return true
    }

    func sell(_ id: String) {
        guard let idx = owned.firstIndex(where: { $0.id == id }) else { return }
        let prop = owned.remove(at: idx)
        cash        += Int(Double(prop.price) * 1.15)
        dailyIncome  = owned.reduce(0) { $0 + $1.incomePerDay }
        netWorth     = cash + owned.reduce(0) { $0 + $1.price }
        save()
    }

    @discardableResult
    func claimPlace(_ place: ClaimedPlace) -> Bool {
        guard cash >= place.price, !isPlaceClaimed(place.id) else { return false }
        claimed.append(place)
        cash     -= place.price
        netWorth  = cash + owned.reduce(0) { $0 + $1.price }
        save()
        return true
    }

    func unclaimPlace(_ id: String) {
        guard let idx = claimed.firstIndex(where: { $0.id == id }) else { return }
        let place = claimed.remove(at: idx)
        cash     += Int(Double(place.price) * 1.15)
        netWorth  = cash + owned.reduce(0) { $0 + $1.price }
        save()
    }

    @discardableResult
    func collectIncome() -> Int {
        let hours  = min(Date().timeIntervalSince(lastCollect) / 3_600, 24)
        let earned = Int(
            owned.reduce(0.0) { $0 + Double($1.incomePerDay) * hours / 24 } +
            claimed.reduce(0.0) { $0 + Double($1.incomePerDay) * hours / 24 }
        )
        guard earned > 0 else { return 0 }
        owned = owned.map { var p = $0; p.totalEarned += Int(Double($0.incomePerDay) * hours / 24); return p }
        cash        += earned
        lastCollect  = Date()
        netWorth     = cash + owned.reduce(0) { $0 + $1.price }
        save()
        return earned
    }

    func addCash(_ amount: Int) { cash += amount; netWorth += amount; save() }

    func reset() {
        playerName  = "Oyuncu"
        cash        = 5_000_000
        netWorth    = 5_000_000
        owned       = []
        claimed     = []
        dailyIncome = 0
        level       = 1
        xp          = 0
        lastCollect = Date()
        PersistenceService.shared.delete()
    }

    // MARK: - Persistence

    func load() {
        guard let state = PersistenceService.shared.load() else { return }
        playerName  = state.playerName
        // Migrate: old default was $50K
        cash        = (state.cash == 50_000 && state.ownedProperties.isEmpty) ? 5_000_000 : state.cash
        level       = state.level
        xp          = state.xp
        lastCollect = state.lastCollect
        owned = state.ownedProperties.compactMap { ops in
            guard let prop = allProperties.first(where: { $0.id == ops.propertyID }) else { return nil }
            return OwnedProperty(id: ops.propertyID, property: prop,
                                 purchasedAt: ops.purchasedAt, totalEarned: ops.totalEarned)
        }
        claimed     = state.claimedPlaces ?? []
        dailyIncome = owned.reduce(0) { $0 + $1.incomePerDay }
        netWorth    = cash + owned.reduce(0) { $0 + $1.price }
    }

    private func save() {
        let state = GameState(
            playerName:      playerName,
            cash:            cash,
            level:           level,
            xp:              xp,
            lastCollect:     lastCollect,
            ownedProperties: owned.map {
                OwnedPropertyState(propertyID: $0.id, purchasedAt: $0.purchasedAt, totalEarned: $0.totalEarned)
            },
            claimedPlaces:   claimed
        )
        PersistenceService.shared.save(state)
    }
}
