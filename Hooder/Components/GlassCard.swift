import SwiftUI

struct GlassCard<Content: View>: View {
    var padding: CGFloat = Sp.lg
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(C.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: R.lg)
                    .stroke(C.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: R.lg))
    }
}
