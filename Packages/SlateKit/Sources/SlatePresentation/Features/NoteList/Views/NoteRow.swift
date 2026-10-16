import SwiftUI
import SlateUI

struct NoteRow: View {
    let model: NoteRowModel
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let status = model.status {
                    StatusDot(color: status.color)
                        .hint(model.statusHint)
                }
                Text(model.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 4)
                Text(model.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if model.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Pinned")
                }
            }
            if model.preview.isEmpty == false {
                Text(model.preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if model.badges.isEmpty == false {
                HStack(spacing: 4) {
                    ForEach(model.badges, id: \.self) { badge in
                        ModelTag(model: badge)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Theme.selection.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(Rectangle())
    }
}

#Preview("Light") {
    VStack(spacing: 0) {
        NoteRow(model: .preview, isSelected: false)
        NoteRow(model: .preview, isSelected: true)
    }
    .frame(width: 300)
    .padding(8)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: 0) {
        NoteRow(model: .preview, isSelected: false)
        NoteRow(model: .preview, isSelected: true)
    }
    .frame(width: 300)
    .padding(8)
    .preferredColorScheme(.dark)
}
