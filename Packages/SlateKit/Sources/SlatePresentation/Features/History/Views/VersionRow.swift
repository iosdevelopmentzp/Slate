import SwiftUI
import SlateUI

struct VersionRow: View {
    let model: VersionRowModel
    let isSelected: Bool

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    if model.isNamed {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.selection)
                            .accessibilityHidden(true)
                    }
                    Text(model.title)
                        .fontWeight(model.isNamed ? .semibold : .regular)
                        .lineLimit(1)
                }
                Text(model.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if let badge = model.badge {
                ModelTag(model: badge)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .softPill(isSelected: isSelected, isHovered: isHovered, radius: 6, base: .clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview("Light") {
    VersionRow(model: .preview, isSelected: true)
        .padding()
        .frame(width: 240)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    VersionRow(model: .preview, isSelected: false)
        .padding()
        .frame(width: 240)
        .preferredColorScheme(.dark)
}
