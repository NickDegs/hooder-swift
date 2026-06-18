import SwiftUI

// iOS 26 gerçek Liquid Glass yardımcıları (mercek kırılması native gelir).
// iOS 26 altında .ultraThinMaterial'a düşer.
extension View {
    @ViewBuilder
    func liquidGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    // Şekilsiz dolgu (kendi clipShape'i olan paneller/HUD için)
    @ViewBuilder
    func liquidGlassFill(_ cornerRadius: CGFloat = 0) -> some View {
        if #available(iOS 26.0, *) {
            if cornerRadius > 0 {
                self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            } else {
                self.glassEffect(.regular, in: .rect)
            }
        } else {
            self.background(.ultraThinMaterial)
        }
    }

    // Etkileşimli cam (butonlar) — basışta sıvı tepki
    @ViewBuilder
    func liquidGlassInteractive<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    // GERÇEK native iOS 26 cam buton stili — yuvarlak kapsül, specular/mercek
    // parlama + yumuşak basış animasyonu yerleşik. iOS<26'da materyal kapsüle düşer.
    @ViewBuilder
    func glassButton(prominent: Bool = false, tint: Color = C.primary) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                self.buttonStyle(.glassProminent).tint(tint).buttonBorderShape(.capsule)
            } else {
                self.buttonStyle(.glass).tint(tint).buttonBorderShape(.capsule)
            }
        } else {
            if prominent {
                self.buttonStyle(.plain).background(tint, in: Capsule())
            } else {
                self.buttonStyle(.plain).background(.ultraThinMaterial, in: Capsule())
            }
        }
    }
}
