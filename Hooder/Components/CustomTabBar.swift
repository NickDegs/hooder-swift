import SwiftUI

private struct TabItem {
    let icon:  String
    let label: String
}

private let tabs: [TabItem] = [
    TabItem(icon: "map.fill",          label: "Harita"),
    TabItem(icon: "building.2.fill",   label: "Portföy"),
    TabItem(icon: "storefront.fill",   label: "Piyasa"),
    TabItem(icon: "trophy.fill",       label: "Sıralama"),
    TabItem(icon: "gearshape.fill",    label: "Ayarlar"),
]

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { idx in
                let t = tabs[idx]
                let active = idx == selectedTab

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = idx
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: t.icon)
                            .font(.system(size: 20, weight: active ? .bold : .regular))
                            .foregroundColor(active ? C.primary : C.textMuted)
                            .scaleEffect(active ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: active)

                        Text(t.label)
                            .font(.tabLabel)
                            .foregroundColor(active ? C.primary : C.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Sp.sm)
                    .background(
                        active
                            ? C.primary.opacity(0.12)
                                .clipShape(RoundedRectangle(cornerRadius: R.md))
                            : Color.clear
                    )
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Sp.md)
        .padding(.top, Sp.sm)
        .padding(.bottom, Sp.sm)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(C.border),
            alignment: .top
        )
    }
}
