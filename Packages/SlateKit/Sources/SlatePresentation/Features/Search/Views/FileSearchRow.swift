import SwiftUI
import SlateDomain
import SlateUI

struct FileSearchRow: View {
    let model: FileSearchRowModel
    let isSelected: Bool

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text(model.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
            } icon: {
                Image(systemName: "doc")
                    .foregroundStyle(.secondary)
            }
            if model.excerpt.characters.isEmpty == false {
                Text(model.excerpt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Label(model.folder, systemImage: "folder")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .softPill(isSelected: isSelected, isHovered: isHovered, radius: Theme.cardRadius, base: Theme.surface)
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    FileSearchRow(model: .preview, isSelected: false)
        .frame(width: 320)
        .padding(12)
        .background(Theme.base)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FileSearchRow(model: .preview, isSelected: true)
        .frame(width: 320)
        .padding(12)
        .background(Theme.base)
        .preferredColorScheme(.dark)
}
