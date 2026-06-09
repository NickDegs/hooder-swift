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
        let key = gameKey
        local.set(data, forKey: key)
        kv.set(data, forKey: key)
        kv.synchronize()
    }

    func load() -> GameState? {
        let key = gameKey
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // iCloud first (survives reinstall), local fallback
        if let data = kv.data(forKey: key),
           let state = try? decoder.decode(GameState.self, from: data) { return state }
        if let data = local.data(forKey: key),
           let state = try? decoder.decode(GameState.self, from: data) { return state }
        return nil
    }

    func delete() {
        let key = gameKey
        kv.removeObject(forKey: key)
        kv.synchronize()
        local.removeObject(forKey: key)
    }
}
