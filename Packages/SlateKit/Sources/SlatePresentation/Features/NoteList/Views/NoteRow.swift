import SwiftUI
import SlateDomain
import SlateUI

struct NoteRow: View {
    let model: NoteRowModel
    let isSelected: Bool
    let isConfirmingTrash: Bool
    let actions: NoteRowActions
    let onCancelTrash: () -> Void
    let onConfirmTrash: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let status = model.status {
                    StatusDot(color: status.color)
                        .hint(model.statusHint)
                        .accessibilityLabel(model.statusHint ?? "")
                }
                if let typeIcon = model.typeIcon {
                    Image(systemName: typeIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .hint(model.typeTitle)
                        .accessibilityLabel(model.typeTitle ?? "")
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
            HStack(spacing: 4) {
                ForEach(model.badges, id: \.self) { badge in
                    ModelTag(model: badge)
                }
                Spacer(minLength: 0)
                HoverActions(isVisible: isHovered || isSelected, count: 2, spacing: 2) {
                    IconButton(systemImage: model.isPinned ? "pin.slash" : "pin", help: model.isPinned ? "Unpin (⌘⇧P)" : "Pin to the top (⌘⇧P)", action: actions.pin)
                        .accessibilityLabel(model.isPinned ? "Unpin" : "Pin")
                    OverflowMenu {
                        NoteRowMenu(isPinned: model.isPinned, actions: actions)
                    }
                    .accessibilityLabel("More actions")
                }
                .opacity(isHovered || isSelected ? 1 : 0)
            }
            if isConfirmingTrash {
                InlineConfirmation(
                    "Move this note to the Trash?",
                    confirmTitle: "Move to Trash",
                    confirmRole: .destructive,
                    systemImage: "trash",
                    onCancel: onCancelTrash,
                    onConfirm: onConfirmTrash
                )
                .onExitCommand(perform: onCancelTrash)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .contextMenu {
            NoteRowMenu(isPinned: model.isPinned, actions: actions)
        }
    }

    private var background: Color {
        if isSelected { return Theme.selection.opacity(0.18) }
        return isHovered ? Theme.hover : .clear
    }
}

#Preview("Light") {
    VStack(spacing: 0) {
        NoteRow(model: .preview, isSelected: false, isConfirmingTrash: false, actions: .preview, onCancelTrash: {}, onConfirmTrash: {})
        NoteRow(model: .preview, isSelected: true, isConfirmingTrash: true, actions: .preview, onCancelTrash: {}, onConfirmTrash: {})
    }
    .frame(width: 320)
    .padding(8)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: 0) {
        NoteRow(model: .preview, isSelected: false, isConfirmingTrash: false, actions: .preview, onCancelTrash: {}, onConfirmTrash: {})
        NoteRow(model: .preview, isSelected: true, isConfirmingTrash: false, actions: .preview, onCancelTrash: {}, onConfirmTrash: {})
    }
    .frame(width: 320)
    .padding(8)
    .preferredColorScheme(.dark)
}
