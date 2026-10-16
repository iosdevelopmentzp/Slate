import AppKit
import SwiftUI

package enum Theme {
    package static let base = Color(nsColor: dynamic(light: NSColor(white: 0.955, alpha: 1), dark: NSColor(white: 0.135, alpha: 1)))
    package static let surface = Color(nsColor: dynamic(light: NSColor(white: 1, alpha: 1), dark: NSColor(white: 0.19, alpha: 1)))
    package static let border = Color(nsColor: .separatorColor)
    package static let text = Color(nsColor: .labelColor)
    package static let secondaryText = Color(nsColor: .secondaryLabelColor)
    package static let selection = Color.accentColor
    package static let codeBackground = Color(nsColor: .quaternaryLabelColor).opacity(0.3)
    package static let hover = Color.primary.opacity(0.05)
    package static let pressedHover = Color.primary.opacity(0.08)
    package static let shadow = Color.black.opacity(0.08)
    package static let softShadow = Color.black.opacity(0.14)
    package static let scrim = Color.black.opacity(0.12)
    package static let warning = Color.orange

    package static let selectionOpacityLight = 0.14
    package static let selectionOpacityDark = 0.22

    package static let fieldRadius: CGFloat = 6
    package static let pillRadius: CGFloat = 8
    package static let cardRadius: CGFloat = 10
    package static let panelRadius: CGFloat = 12
    package static let quickNoteRadius: CGFloat = 14

    package static let cardPadding: CGFloat = 12
    package static let cardGap: CGFloat = 6
    package static let columnPadding: CGFloat = 12

    package static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }

    package static let hoverAnimation = Animation.easeInOut(duration: 0.15)
    package static let sidebarAnimation = Animation.easeInOut(duration: 0.2)
}
