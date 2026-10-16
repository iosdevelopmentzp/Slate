import SwiftUI

package extension View {

    func softPill(isSelected: Bool, isHovered: Bool, radius: CGFloat = Theme.pillRadius, base: Color = .clear) -> some View {
        modifier(SoftPill(isSelected: isSelected, isHovered: isHovered, radius: radius, base: base))
    }
}
