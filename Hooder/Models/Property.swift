import Foundation
import CoreLocation

// MARK: - PropertyCategory

enum PropertyCategory: String, CaseIterable, Codable {
    case hotel, office, retail, residential, land, industrial
    case park, street, marina, landmark, stadium, parking
    case apartment, villa, penthouse, duplex, studio, building
    case townhouse, yali, garden_unit, rooftop_unit

    var emoji: String {
        switch self {
        case .hotel:        return "🏨"
        case .office:       return "🏢"
        case .retail:       return "🏪"
        case .residential:  return "🏠"
        case .land:         return "🌿"
        case .industrial:   return "🏭"
        case .park:         return "🌳"
        case .street:       return "🛣️"
        case .marina:       return "⛵"
        case .landmark:     return "🏛️"
        case .stadium:      return "🏟️"
        case .parking:      return "🅿️"
        case .apartment:    return "🏠"
        case .villa:        return "🏡"
        case .penthouse:    return "✨"
        case .duplex:       return "🏘️"
        case .studio:       return "🛋️"
        case .building:     return "🏗️"
        case .townhouse:    return "🏚️"
        case .yali:         return "🚤"
        case .garden_unit:  return "🌺"
        case .rooftop_unit: return "🌇"
        }
    }

    var label: String {
        switch self {
        case .hotel:        return "Otel"
        case .office:       return "Ofis"
        case .retail:       return "Mağaza"
        case .residential:  return "Konut"
        case .land:         return "Arsa"
        case .industrial:   return "Endüstri"
        case .park:         return "Park/Bahçe"
        case .street:       return "Cadde/Sokak"
        case .marina:       return "Marina/Liman"
        case .landmark:     return "Meydan/Eser"
        case .stadium:      return "Stadyum/Arena"
        case .parking:      return "Otopark"
        case .apartment:    return "Daire"
        case .villa:        return "Villa/Müstakil"
        case .penthouse:    return "Penthouse"
        case .duplex:       return "Dubleks"
        case .studio:       return "Stüdyo"
        case .building:     return "Bina/Blok"
        case .townhouse:    return "Sıra Ev"
        case .yali:         return "Yalı"
        case .garden_unit:  return "Bahçe Katı"
        case .rooftop_unit: return "Çatı Katı"
        }
    }

    var accentHex: String {
        switch self {
        case .hotel:        return "#3494ff"
        case .office:       return "#bf5af2"
        case .retail:       return "#ffc434"
        case .residential:  return "#30d158"
        case .land:         return "#30b0c7"
        case .industrial:   return "#ff6b35"
        case .park:         return "#34c759"
        case .street:       return "#ff9f0a"
        case .marina:       return "#0a84ff"
        case .landmark:     return "#ffd60a"
        case .stadium:      return "#ff375f"
        case .parking:      return "#8e8e93"
        case .apartment:    return "#30d158"
        case .villa:        return "#34c759"
        case .penthouse:    return "#ffd60a"
        case .duplex:       return "#ff9f0a"
        case .studio:       return "#5856d6"
        case .building:     return "#0a84ff"
        case .townhouse:    return "#ff6b35"
        case .yali:         return "#0a84ff"
        case .garden_unit:  return "#30d158"
        case .rooftop_unit: return "#ff9f0a"
        }
    }
}

// MARK: - Property

struct Property: Identifiable, Hashable, Codable {
    let id:           String
    let name:         String
    let address:      String
    let category:     PropertyCategory
    let neighborhood: String
    let city:         String
    let country:      String
    let price:        Int
    let incomePerDay: Int
    let prestige:     Int
    let lat:          Double
    let lng:          Double
    let description:  String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    var roiPercent: Double { Double(incomePerDay) * 365 / Double(price) * 100 }
    var accentHex: String  { category.accentHex }
}

// MARK: - City

struct City: Identifiable {
    let id:      String
    let name:    String
    let country: String
    let flag:    String
    let lat:     Double
    let lng:     Double
    let zoom:    Double
}

// MARK: - HoodGroup

struct HoodGroup: Identifiable {
    let key:          String
    let neighborhood: String
    let city:         String
    let country:      String
    let flag:         String
    let lat:          Double
    let lng:          Double
    let properties:   [Property]
    var id: String { key }
}

// MARK: - ClaimedPlace

struct ClaimedPlace: Identifiable, Codable {
    let id:           String
    let name:         String
    let address:      String
    let placeType:    String
    let lat:          Double
    let lng:          Double
    let price:        Int
    let incomePerDay: Int
    let purchasedAt:  Date
}

// MARK: - PlaceClaimInfo

struct PlaceClaimInfo {
    let name:      String
    let address:   String
    let placeType: String
    let lat:       Double
    let lng:       Double
}

// MARK: - Group Helpers

func buildHoodGroups() -> [HoodGroup] {
    let flagMap = Dictionary(uniqueKeysWithValues: allCities.map { ($0.name, $0.flag) })
    var map: [String: (String, String, String, [Property])] = [:]
    for prop in allProperties {
        let key = "\(prop.city)::\(prop.neighborhood)"
        if map[key] == nil { map[key] = (prop.neighborhood, prop.city, prop.country, []) }
        map[key]!.3.append(prop)
    }
    return map.map { key, val in
        let props = val.3
        let lat = props.map(\.lat).reduce(0, +) / Double(props.count)
        let lng = props.map(\.lng).reduce(0, +) / Double(props.count)
        return HoodGroup(key: key, neighborhood: val.0, city: val.1, country: val.2,
                         flag: flagMap[val.1] ?? "🌍", lat: lat, lng: lng, properties: props)
    }.sorted { $0.city < $1.city || ($0.city == $1.city && $0.neighborhood < $1.neighborhood) }
}

func nearestHood(_ hoods: [HoodGroup], lat: Double, lng: Double) -> HoodGroup? {
    hoods.min { a, b in
        let da = (a.lat - lat) * (a.lat - lat) + (a.lng - lng) * (a.lng - lng)
        let db = (b.lat - lat) * (b.lat - lat) + (b.lng - lng) * (b.lng - lng)
        return da < db
    }
}

// MARK: - Formatters

func formatPrice(_ n: Int) -> String {
    if n >= 1_000_000 { return "$\(String(format: "%.1f", Double(n) / 1_000_000))M" }
    if n >= 1_000     { return "$\(n / 1_000)K" }
    return "$\(n)"
}

func formatIncome(_ n: Int) -> String {
    if n >= 1_000 { return "+$\(String(format: "%.1f", Double(n) / 1_000))K/gün" }
    return "+$\(n)/gün"
}

// MARK: - Place Pricing

func placeId(lat: Double, lng: Double) -> String {
    "place_\(String(format: "%.4f", lat))_\(String(format: "%.4f", lng))"
}

private func deterministicHash(lat: Double, lng: Double) -> Int {
    let x = Int(lat * 10000) & 0xffff
    let y = Int(lng * 10000) & 0xffff
    return ((x &* 31337) ^ (y &* 7919)) & 0xffffff
}

private let placeTypeMults: [String: Int] = [
    "poi": 18, "building": 10, "road": 80, "natural": 25,
    "place": 40, "transit": 35, "park": 20, "airport": 60,
    "land": 6, "water": 30, "waterway": 22,
]

func generatePlacePrice(lat: Double, lng: Double, placeType: String) -> Int {
    let h    = deterministicHash(lat: lat, lng: lng)
    let base = 50_000 + (h % 100) * 15_000
    let mult = placeTypeMults.first(where: { placeType.contains($0.key) })?.value ?? 8
    let raw  = base * mult / 100_000 * 100_000
    return max(raw, 100_000)
}

func generatePlaceIncome(price: Int) -> Int { max(Int(Double(price) * 0.000022), 1) }

func placeTypeEmoji(_ type: String) -> String {
    if type.contains("poi")      { return "📍" }
    if type.contains("road")     { return "🛣️" }
    if type.contains("park")     { return "🌳" }
    if type.contains("transit")  { return "🚉" }
    if type.contains("building") { return "🏗️" }
    if type.contains("natural")  { return "🌿" }
    if type.contains("place")    { return "📌" }
    if type.contains("airport")  { return "✈️" }
    if type.contains("water")    { return "💧" }
    return "🏠"
}

func placeTypeLabel(_ type: String) -> String {
    if type.contains("poi")      { return "İşletme/POİ" }
    if type.contains("road")     { return "Yol/Cadde" }
    if type.contains("park")     { return "Park/Bahçe" }
    if type.contains("transit")  { return "Ulaşım Noktası" }
    if type.contains("building") { return "Bina" }
    if type.contains("natural")  { return "Doğal Alan" }
    if type.contains("place")    { return "Bölge/Mahalle" }
    if type.contains("airport")  { return "Havalimanı" }
    if type.contains("water")    { return "Su Kıyısı" }
    return "Konum"
}

func placeTypeAccent(_ type: String) -> String {
    if type.contains("poi")      { return "#ff9f0a" }
    if type.contains("road")     { return "#ff9500" }
    if type.contains("park")     { return "#34c759" }
    if type.contains("transit")  { return "#30b0c7" }
    if type.contains("building") { return "#0a84ff" }
    if type.contains("natural")  { return "#34c759" }
    if type.contains("place")    { return "#bf5af2" }
    if type.contains("airport")  { return "#ff375f" }
    if type.contains("water")    { return "#0a84ff" }
    return "#aeaeb2"
}
