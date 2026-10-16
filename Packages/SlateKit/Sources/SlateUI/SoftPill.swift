import SwiftUI

package struct SoftPill: ViewModifier {
    package let isSelected: Bool
    package let isHovered: Bool
    package let radius: CGFloat
    package let base: Color

    @Environment(\.colorScheme) private var colorScheme

    package init(isSelected: Bool, isHovered: Bool, radius: CGFloat, base: Color = .clear) {
        self.isSelected = isSelected
        self.isHovered = isHovered
        self.radius = radius
        self.base = base
    }

    package func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(base)
                    .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
            }
            .animation(Theme.hoverAnimation, value: isSelected)
            .animation(Theme.hoverAnimation, value: isHovered)
    }

    private var fill: Color {
        let selected = colorScheme == .dark ? Theme.selectionOpacityDark : Theme.selectionOpacityLight
        if isSelected {
            return Theme.selection.opacity(isHovered ? selected + 0.06 : selected)
        }
        return isHovered ? Theme.hover : .clear
    }
}
