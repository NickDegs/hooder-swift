import Foundation

// MARK: - Codable State

struct OwnedPropertyState: Codable {
    let propertyID:  String
    let purchasedAt: Date
    var totalEarned: Int
}

struct GameState: Codable {
    var playerName:       String
    var cash:             Int
    var level:            Int
    var xp:               Int
    var lastCollect:      Date
    var ownedProperties:  [OwnedPropertyState]
    var claimedPlaces:    [ClaimedPlace]?
}

// MARK: - Persistence

final class PersistenceService {
    static let shared = PersistenceService()

    private let kv    = NSUbiquitousKeyValueStore.default
    private let local = UserDefaults.standard
    private var userID = ""

    private var gameKey: String { "game_\(userID.isEmpty ? "anonymous" : userID)" }

    func setUserID(_ uid: String) { userID = uid }

    func save(_ state: GameState) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(state) else { return }
        local.set(data, forKey: gameKey)
        kv.set(data, forKey: gameKey)
        kv.synchronize()
    }

    func load() -> GameState? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = kv.data(forKey: gameKey),
           let state = try? decoder.decode(GameState.self, from: data) { return state }
        if let data = local.data(forKey: gameKey),
           let state = try? decoder.decode(GameState.self, from: data) { return state }
        return nil
    }

    func delete() {
        kv.removeObject(forKey: gameKey)
        kv.synchronize()
        local.removeObject(forKey: gameKey)
    }
}
