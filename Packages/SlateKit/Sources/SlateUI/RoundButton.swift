import SwiftUI

package struct RoundButton: View {
    package let systemImage: String
    package let help: String
    package let isProminent: Bool
    package let action: () -> Void

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled

    package static let side: CGFloat = 28

    package init(systemImage: String, help: String, isProminent: Bool = false, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.help = help
        self.isProminent = isProminent
        self.action = action
    }

    package var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: Self.side, height: Self.side)
                .background(background, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(Theme.hoverAnimation, value: isHovered)
        .hint(help)
        .accessibilityLabel(help)
    }

    private var foreground: Color {
        guard isEnabled else { return Color.secondary.opacity(0.5) }
        return isProminent ? Theme.selection : (isHovered ? Color.primary : Color.secondary)
    }

    private var background: Color {
        if isProminent {
            return Theme.selection.opacity(isHovered ? 0.22 : 0.14)
        }
        return isHovered ? Theme.pressedHover : Theme.hover
    }
}

#Preview("Light") {
    HStack {
        RoundButton(systemImage: "plus", help: "New note", isProminent: true) {}
        RoundButton(systemImage: "ellipsis", help: "More") {}
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    HStack {
        RoundButton(systemImage: "plus", help: "New note", isProminent: true) {}
        RoundButton(systemImage: "ellipsis", help: "More") {}
    }
    .padding()
    .preferredColorScheme(.dark)
}
