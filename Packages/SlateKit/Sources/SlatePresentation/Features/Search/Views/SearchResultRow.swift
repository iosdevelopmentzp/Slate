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
                if let typeIcon = model.typeIcon {
                    Image(systemName: typeIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                Text(model.title)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 4)
                Text(model.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if model.snippet.characters.isEmpty == false {
                Text(model.snippet)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: 4) {
                if let folder = model.folder {
                    ModelTag(model: TagModel(folder, systemImage: "folder"))
                }
                ForEach(model.badges, id: \.self) { badge in
                    ModelTag(model: badge)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }

    private var background: Color {
        if isSelected { return Theme.selection.opacity(0.18) }
        return isHovered ? Theme.hover : .clear
    }
}

#Preview("Light") {
    SearchResultRow(model: .preview, isSelected: false)
        .frame(width: 320)
        .padding(8)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SearchResultRow(model: .preview, isSelected: true)
        .frame(width: 320)
        .padding(8)
        .preferredColorScheme(.dark)
}
