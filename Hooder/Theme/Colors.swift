import SwiftUI

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum C {
    static let bg          = Color(hex: "#04080f")
    static let bgCard      = Color(hex: "#0c1220")
    static let bgElevated  = Color(hex: "#141e30")
    static let bgSheet     = Color(hex: "#060b16")

    static let primary     = Color(hex: "#3494ff")
    static let gold        = Color(hex: "#ffc434")
    static let green       = Color(hex: "#30d158")
    static let red         = Color(hex: "#ff453a")
    static let purple      = Color(hex: "#bf5af2")

    static let text        = Color(hex: "#f2f2f7")
    static let textSub     = Color(hex: "#aeaeb2")
    static let textMuted   = Color(hex: "#6e6e76")

    static let border      = Color.white.opacity(0.11)
    static let specular    = Color.white.opacity(0.17)
    static let overlay     = Color.black.opacity(0.72)
}

enum Sp {
    static let xs: CGFloat  =  4
    static let sm: CGFloat  =  8
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 16
    static let xl: CGFloat  = 20
    static let x2: CGFloat  = 24
    static let x3: CGFloat  = 32
    static let x4: CGFloat  = 48
}

enum R {
    static let xs: CGFloat  =  4
    static let sm: CGFloat  =  8
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 16
    static let xl: CGFloat  = 20
    static let x2: CGFloat  = 26
    static let full: CGFloat = 9999
}
