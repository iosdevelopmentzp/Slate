import SwiftUI
import SlateUI

struct TodoRow: View {
    let text: String
    let onToggle: () -> Void
    let onOpen: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: "square")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Check \(text)")
            Text(text.isEmpty ? " " : text)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(count: 2, perform: onOpen)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(isHovered ? Theme.hover : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Check", systemImage: "checkmark.square", action: onToggle)
            Button("Open the note", systemImage: "arrow.right.circle", action: onOpen)
        }
    }
}

#Preview("Light") {
    TodoRow(text: "Break the delegate cycle", onToggle: {}, onOpen: {})
        .frame(width: 320)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    TodoRow(text: "Break the delegate cycle", onToggle: {}, onOpen: {})
        .frame(width: 320)
        .preferredColorScheme(.dark)
}
