import SwiftUI

struct StatBadge: View {
    let label: String
    let value: String
    var accent: Color = C.primary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.stat)
                .foregroundStyle(accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label.uppercased())
                .font(.label_)
                .foregroundStyle(C.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Sp.md)
        .background {
            RoundedRectangle(cornerRadius: R.md, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: R.md, style: .continuous)
                        .stroke(C.border, lineWidth: 0.5)
                }
        }
    }
}
