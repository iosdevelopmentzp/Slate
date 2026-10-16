import SwiftUI
import SlateUI

struct TrashRow: View {
    let model: TrashRowModel
    let onRestore: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var isConfirming = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            row
            if isConfirming {
                InlineConfirmation(
                    "Delete this note now? It goes to the macOS Trash.",
                    confirmTitle: "Delete now",
                    confirmRole: .destructive,
                    systemImage: "trash",
                    onCancel: { isConfirming = false },
                    onConfirm: {
                        isConfirming = false
                        onDelete()
                    }
                )
                .onExitCommand { isConfirming = false }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Theme.hover : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Restore", systemImage: "arrow.uturn.backward", action: onRestore)
            Button("Delete now", systemImage: "trash", role: .destructive) { isConfirming = true }
        }
    }

    private var row: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Text(model.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            HStack(spacing: 4) {
                Button("Restore", action: onRestore)
                    .accessibilityLabel("Restore \(model.title)")
                Button("Delete now") { isConfirming = true }
                    .accessibilityLabel("Delete \(model.title) now")
            }
            .controlSize(.small)
            .opacity(isHovered ? 1 : 0)
        }
    }
}

#Preview("Light") {
    TrashRow(model: .preview, onRestore: {}, onDelete: {})
        .frame(width: 320)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TrashRow(model: .preview, onRestore: {}, onDelete: {})
        .frame(width: 320)
        .preferredColorScheme(.dark)
}
