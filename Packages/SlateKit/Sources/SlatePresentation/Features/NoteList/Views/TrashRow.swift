import SwiftUI
import SlateUI

struct TrashRow: View {
    let model: TrashRowModel
    let onRestore: () -> Void

    @State private var isHovered = false

    var body: some View {
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
            Button("Restore", action: onRestore)
                .controlSize(.small)
                .opacity(isHovered ? 1 : 0)
                .accessibilityLabel("Restore \(model.title)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Theme.hover : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Restore", systemImage: "arrow.uturn.backward", action: onRestore)
        }
    }
}

#Preview("Light") {
    TrashRow(model: .preview, onRestore: {})
        .frame(width: 320)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TrashRow(model: .preview, onRestore: {})
        .frame(width: 320)
        .preferredColorScheme(.dark)
}
