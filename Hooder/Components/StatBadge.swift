import SwiftUI

struct StatBadge: View {
    let label: String
    let value: String
    var accent: Color = C.primary

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.stat)
                .foregroundColor(accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label.uppercased())
                .font(.label_)
                .foregroundColor(C.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Sp.md)
        .background(C.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: R.md))
    }
}
