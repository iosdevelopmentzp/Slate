import AppKit

nonisolated package struct EditorColors: Equatable, Sendable {
    package var text: NSColor
    package var secondaryText: NSColor
    package var link: NSColor
    package var accent: NSColor
    package var codeBackground: NSColor
    package var rawBackground: NSColor
    package var quoteBar: NSColor
    package var checkboxBorder: NSColor
    package var divider: NSColor
    package var imageBorder: NSColor

    package init(
        text: NSColor,
        secondaryText: NSColor,
        link: NSColor,
        accent: NSColor,
        codeBackground: NSColor,
        rawBackground: NSColor,
        quoteBar: NSColor,
        checkboxBorder: NSColor,
        divider: NSColor,
        imageBorder: NSColor
    ) {
        self.text = text
        self.secondaryText = secondaryText
        self.link = link
        self.accent = accent
        self.codeBackground = codeBackground
        self.rawBackground = rawBackground
        self.quoteBar = quoteBar
        self.checkboxBorder = checkboxBorder
        self.divider = divider
        self.imageBorder = imageBorder
    }

    package static let system = EditorColors(
        text: .labelColor,
        secondaryText: .secondaryLabelColor,
        link: .controlAccentColor,
        accent: .controlAccentColor,
        codeBackground: dynamic(light: NSColor(white: 0, alpha: 0.05), dark: NSColor(white: 1, alpha: 0.08)),
        rawBackground: dynamic(light: NSColor.systemOrange.withAlphaComponent(0.08), dark: NSColor.systemOrange.withAlphaComponent(0.12)),
        quoteBar: .controlAccentColor.withAlphaComponent(0.55),
        checkboxBorder: .tertiaryLabelColor,
        divider: .separatorColor,
        imageBorder: .separatorColor
    )

    private static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }
}
