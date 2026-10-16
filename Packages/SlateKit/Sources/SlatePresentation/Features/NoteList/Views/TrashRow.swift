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
            Text(model.title)
                .font(.body.weight(.semibold))
                .lineLimit(1)
            Text(model.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if isConfirming {
                HStack(spacing: 4) {
                    Text("Delete now?")
                        .foregroundStyle(.secondary)
                    Button("Yes") {
                        isConfirming = false
                        onDelete()
                    }
                    .buttonStyle(.plain)
                    .fontWeight(.semibold)
                    .foregroundStyle(Tint.red.color)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Button("No") { isConfirming = false }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .padding(.top, 4)
                .onExitCommand { isConfirming = false }
            } else {
                HStack(spacing: 8) {
                    Button("Restore", action: onRestore)
                        .accessibilityLabel("Restore \(model.title)")
                    Button("Delete now") { isConfirming = true }
                        .accessibilityLabel("Delete \(model.title) now")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .padding(.top, 4)
                .opacity(isHovered ? 1 : 0)
            }
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .softPill(isSelected: false, isHovered: isHovered, radius: Theme.cardRadius, base: Theme.surface)
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Restore", systemImage: "arrow.uturn.backward", action: onRestore)
            Button("Delete now", systemImage: "trash", role: .destructive) { isConfirming = true }
        }
    }
}

#Preview("Light") {
    TrashRow(model: .preview, onRestore: {}, onDelete: {})
        .frame(width: 320)
        .padding(12)
        .background(Theme.base)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TrashRow(model: .preview, onRestore: {}, onDelete: {})
        .frame(width: 320)
        .padding(12)
        .background(Theme.base)
        .preferredColorScheme(.dark)
}
