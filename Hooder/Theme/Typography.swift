import SwiftUI

// SwiftUI metin stilleri — React Native TEXT sabitine birebir karşılık
extension Font {
    static let display  = Font.system(size: 34, weight: .black,     design: .default)
    static let h1       = Font.system(size: 28, weight: .black,     design: .default)
    static let h2       = Font.system(size: 22, weight: .black,     design: .default)
    static let h3       = Font.system(size: 18, weight: .heavy,     design: .default)
    static let h4       = Font.system(size: 16, weight: .bold,      design: .default)
    static let body_    = Font.system(size: 14, weight: .regular,   design: .default)
    static let bodyBold = Font.system(size: 14, weight: .bold,      design: .default)
    static let caption_ = Font.system(size: 12, weight: .regular,   design: .default)
    static let label_   = Font.system(size: 10, weight: .bold,      design: .default)
    static let btnLg    = Font.system(size: 16, weight: .black,     design: .default)
    static let btnMd    = Font.system(size: 14, weight: .black,     design: .default)
    static let btnSm    = Font.system(size: 12, weight: .bold,      design: .default)
    static let price    = Font.system(size: 22, weight: .black,     design: .default)
    static let stat     = Font.system(size: 18, weight: .black,     design: .default)
    static let tabLabel = Font.system(size:  9, weight: .bold,      design: .default)
}

extension View {
    func tracked(_ spacing: CGFloat) -> some View {
        self.kerning(spacing)
    }
}
