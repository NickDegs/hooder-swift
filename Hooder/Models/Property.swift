import Foundation
import CoreLocation

// MARK: - Types

enum PropertyCategory: String, CaseIterable, Codable {
    case hotel, office, retail, residential, land, industrial

    var emoji: String {
        switch self {
        case .hotel:       return "🏨"
        case .office:      return "🏢"
        case .retail:      return "🏪"
        case .residential: return "🏠"
        case .land:        return "🌿"
        case .industrial:  return "🏭"
        }
    }

    var label: String {
        switch self {
        case .hotel:       return "Hotel"
        case .office:      return "Office"
        case .retail:      return "Retail"
        case .residential: return "Home"
        case .land:        return "Land"
        case .industrial:  return "Industrial"
        }
    }

    var accentHex: String {
        switch self {
        case .hotel:       return "#3494ff"
        case .office:      return "#bf5af2"
        case .retail:      return "#ffc434"
        case .residential: return "#30d158"
        case .land:        return "#30b0c7"
        case .industrial:  return "#ff6b35"
        }
    }
}

// MARK: - Property

struct Property: Identifiable, Hashable, Codable {
    let id:           String
    let name:         String
    let category:     PropertyCategory
    let neighborhood: String
    let city:         String
    let country:      String
    let price:        Int
    let incomePerDay: Int
    let prestige:     Int        // 1–5
    let lat:          Double
    let lng:          Double
    let description:  String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var roiPercent: Double {
        Double(incomePerDay) * 365 / Double(price) * 100
    }

    var thumbURL: URL? {
        let color = accentHex.replacingOccurrences(of: "#", with: "")
        let token = Bundle.main.infoDictionary?["MBXAccessToken"] as? String ?? ""
        let s = "https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/static/pin-s+\(color)(\(lng),\(lat))/\(lng),\(lat),15,0/104x104@2x?access_token=\(token)"
        return URL(string: s)
    }

    var accentHex: String { category.accentHex }
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

// MARK: - Helpers

func formatPrice(_ n: Int) -> String {
    if n >= 1_000_000 { return "$\(String(format: "%.1f", Double(n)/1_000_000))M" }
    if n >= 1_000     { return "$\(n / 1_000)K" }
    return "$\(n)"
}

func formatIncome(_ n: Int) -> String {
    if n >= 1_000 { return "$\(String(format: "%.1f", Double(n)/1_000))K/day" }
    return "$\(n)/day"
}
