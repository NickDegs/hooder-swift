import SwiftUI

struct GlassTabBar: View {
    @Binding var selectedTab: Int

    private let items: [(icon: String, label: String)] = [
        ("map.fill",                  "Harita"),
        ("storefront.fill",           "Piyasa"),
        ("chart.line.uptrend.xyaxis", "Portföy"),
        ("trophy.fill",               "Sıralama"),
        ("gearshape.fill",            "Ayarlar"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                let active = idx == selectedTab
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                        selectedTab = idx
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 19, weight: active ? .bold : .medium))
                            .foregroundStyle(active ? C.primary : C.textMuted)
                            .scaleEffect(active ? 1.08 : 1.0)
                            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: active)

                        Text(item.label)
                            .font(.tabLabel)
                            .foregroundStyle(active ? C.primary : C.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Sp.sm)
                    .background(
                        active ? C.primary.opacity(0.14) : Color.clear,
                        in: RoundedRectangle(cornerRadius: R.sm, style: .continuous)
                    )
                    .padding(.horizontal, Sp.xs)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Sp.sm)
        .padding(.vertical, Sp.xs)
        .modifier(TabBarGlass())
        .shadow(color: .black.opacity(0.3), radius: 14, y: 4)
        .padding(.horizontal, Sp.lg)
        .padding(.bottom, 12)
    }
}

// iOS 26 Liquid Glass tab bar zemini; altında .ultraThinMaterial'a düşer.
private struct TabBarGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: .rect(cornerRadius: R.x2))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: R.x2, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: R.x2, style: .continuous)
                        .stroke(C.specular, lineWidth: 0.5)
                }
        }
    }
}
