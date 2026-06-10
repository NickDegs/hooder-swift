import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = R.lg
    var padding: CGFloat = Sp.lg
    @ViewBuilder let content: () -> Content

    var body: some View {
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
