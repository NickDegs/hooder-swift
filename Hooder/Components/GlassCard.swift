import SwiftUI

// iOS 26 gerçek Liquid Glass (.glassEffect). iOS 26 altında .ultraThinMaterial'a düşer.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = R.lg
    var padding: CGFloat = Sp.lg
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 26.0, *) {
            content()
                .padding(padding)
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            content()
                .padding(padding)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(C.specular, lineWidth: 0.5)
                        }
                }
        }
    }
}
