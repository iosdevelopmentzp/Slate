import SwiftUI
import SlateDomain
import SlateUI

struct NoteCard: View {
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
                Text(model.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 4)
                if model.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.selection)
                        .accessibilityLabel("Pinned")
                }
                Text(model.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text(model.preview.isEmpty ? " " : model.preview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2, reservesSpace: true)
                .padding(.trailing, 28)
            if isConfirmingTrash {
                confirmation
            }
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .softPill(isSelected: isSelected, isHovered: isHovered, radius: Theme.cardRadius, base: Theme.surface)
        .overlay(alignment: .bottomTrailing) {
            if isConfirmingTrash == false {
                OverflowMenu {
                    NoteRowMenu(isPinned: model.isPinned, actions: actions)
                }
                .background(Theme.base.opacity(0.9), in: Circle())
                .padding(8)
                .opacity(isHovered ? 1 : 0)
                .accessibilityLabel("More for \(model.title)")
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .onHover { isHovered = $0 }
        .contextMenu {
            NoteRowMenu(isPinned: model.isPinned, actions: actions)
        }
        .draggable(NoteDragPayload.text(for: model.id))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.title)
    }

    private var confirmation: some View {
        HStack(spacing: 4) {
            Text("Move to the Trash?")
                .foregroundStyle(.secondary)
            Button("Yes", action: onConfirmTrash)
                .buttonStyle(.plain)
                .fontWeight(.semibold)
                .foregroundStyle(Tint.red.color)
            Text("·")
                .foregroundStyle(.secondary)
            Button("No", action: onCancelTrash)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .font(.callout)
        .padding(.top, 4)
        .onExitCommand(perform: onCancelTrash)
    }
}

#Preview("Light") {
    VStack(spacing: Theme.cardGap) {
        NoteCard(model: .preview, isSelected: false, isConfirmingTrash: false, actions: .preview, onCancelTrash: {}, onConfirmTrash: {})
        NoteCard(model: .preview, isSelected: true, isConfirmingTrash: true, actions: .preview, onCancelTrash: {}, onConfirmTrash: {})
    }
    .frame(width: 320)
    .padding(12)
    .background(Theme.base)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: Theme.cardGap) {
        NoteCard(model: .preview, isSelected: false, isConfirmingTrash: false, actions: .preview, onCancelTrash: {}, onConfirmTrash: {})
        NoteCard(model: .preview, isSelected: true, isConfirmingTrash: false, actions: .preview, onCancelTrash: {}, onConfirmTrash: {})
    }
    .frame(width: 320)
    .padding(12)
    .background(Theme.base)
    .preferredColorScheme(.dark)
}
