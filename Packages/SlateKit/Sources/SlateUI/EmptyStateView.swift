import SwiftUI

package struct EmptyStateView: View {
    package let systemImage: String
    package let title: String
    package let actionTitle: String?
    package let shortcut: String?
    package let action: () -> Void

    package init(systemImage: String, title: String, actionTitle: String? = nil, shortcut: String? = nil, action: @escaping () -> Void = {}) {
        self.systemImage = systemImage
        self.title = title
        self.actionTitle = actionTitle
        self.shortcut = shortcut
        self.action = action
    }

    package var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(Theme.selection)
                .frame(width: 64, height: 64)
                .background(Theme.selection.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(AccentButtonStyle())
            }
            if let shortcut {
                Text(shortcut)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Light") {
    EmptyStateView(systemImage: "square.and.pencil", title: "Nothing here yet.", actionTitle: "New note", shortcut: "⌘N")
        .frame(width: 320, height: 360)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    EmptyStateView(systemImage: "note.text", title: "Pick a note or press ⌘N.")
        .frame(width: 320, height: 360)
        .preferredColorScheme(.dark)
}
