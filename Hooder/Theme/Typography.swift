import SwiftUI

extension Font {
    static let display  = Font.system(size: 36, weight: .black,  design: .rounded)
    static let h1       = Font.system(size: 28, weight: .black,  design: .rounded)
    static let h2       = Font.system(size: 22, weight: .black,  design: .rounded)
    static let h3       = Font.system(size: 18, weight: .heavy,  design: .rounded)
    static let h4       = Font.system(size: 16, weight: .bold,   design: .rounded)
    static let body_    = Font.system(size: 14, weight: .regular, design: .rounded)
    static let bodyBold = Font.system(size: 14, weight: .bold,   design: .rounded)
    static let caption_ = Font.system(size: 12, weight: .regular, design: .rounded)
    static let label_   = Font.system(size: 10, weight: .bold,   design: .rounded)
    static let btnLg    = Font.system(size: 16, weight: .black,  design: .rounded)
    static let btnMd    = Font.system(size: 14, weight: .black,  design: .rounded)
    static let btnSm    = Font.system(size: 12, weight: .bold,   design: .rounded)
    static let price    = Font.system(size: 22, weight: .black,  design: .rounded)
    static let stat     = Font.system(size: 18, weight: .black,  design: .rounded)
    static let tabLabel = Font.system(size:  9, weight: .bold,   design: .rounded)
}

extension Text {
    func tracked(_ spacing: CGFloat) -> Text {
        self.kerning(spacing)
    }
}
