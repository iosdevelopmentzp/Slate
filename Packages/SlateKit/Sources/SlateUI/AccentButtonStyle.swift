import SwiftUI

package struct AccentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    package init() {}

    package func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Theme.selection.opacity(fillOpacity(isPressed: configuration.isPressed)), in: Capsule())
            .contentShape(Capsule())
            .animation(Theme.hoverAnimation, value: configuration.isPressed)
    }

    private func fillOpacity(isPressed: Bool) -> Double {
        guard isEnabled else { return 0.4 }
        return isPressed ? 0.8 : 1
    }
}
