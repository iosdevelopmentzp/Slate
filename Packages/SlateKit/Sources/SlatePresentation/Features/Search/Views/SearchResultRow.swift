import SwiftUI
import SlateDomain
import SlateUI

struct SearchResultRow: View {
    let model: SearchResultRowModel
    let isSelected: Bool

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(model.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 4)
                Text(model.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if model.excerpt.characters.isEmpty == false {
                Text(model.excerpt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let folder = model.folder {
                Label(folder, systemImage: "folder")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .softPill(isSelected: isSelected, isHovered: isHovered, radius: Theme.cardRadius, base: Theme.surface)
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .onHover { isHovered = $0 }
        .draggable(NoteDragPayload.text(for: model.id))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    SearchResultRow(model: .preview, isSelected: false)
        .frame(width: 320)
        .padding(12)
        .background(Theme.base)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SearchResultRow(model: .preview, isSelected: true)
        .frame(width: 320)
        .padding(12)
        .background(Theme.base)
        .preferredColorScheme(.dark)
}
