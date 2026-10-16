import AppKit

nonisolated package struct EditorColors: Equatable, Sendable {
    package var text: NSColor
    package var secondaryText: NSColor
    package var mark: NSColor
    package var link: NSColor
    package var codeText: NSColor
    package var codeBackground: NSColor
    package var quoteBar: NSColor
    package var chipBackground: NSColor
    package var checkbox: NSColor
    package var keyword: NSColor
    package var string: NSColor
    package var comment: NSColor
    package var number: NSColor
    package var type: NSColor
    package var attribute: NSColor
    package var added: NSColor
    package var removed: NSColor

    package init(
        text: NSColor,
        secondaryText: NSColor,
        mark: NSColor,
        link: NSColor,
        codeText: NSColor,
        codeBackground: NSColor,
        quoteBar: NSColor,
        chipBackground: NSColor,
        checkbox: NSColor,
        keyword: NSColor,
        string: NSColor,
        comment: NSColor,
        number: NSColor,
        type: NSColor,
        attribute: NSColor,
        added: NSColor,
        removed: NSColor
    ) {
        self.text = text
        self.secondaryText = secondaryText
        self.mark = mark
        self.link = link
        self.codeText = codeText
        self.codeBackground = codeBackground
        self.quoteBar = quoteBar
        self.chipBackground = chipBackground
        self.checkbox = checkbox
        self.keyword = keyword
        self.string = string
        self.comment = comment
        self.number = number
        self.type = type
        self.attribute = attribute
        self.added = added
        self.removed = removed
    }

    package static let system = EditorColors(
        text: .labelColor,
        secondaryText: .secondaryLabelColor,
        mark: .tertiaryLabelColor,
        link: .linkColor,
        codeText: .labelColor,
        codeBackground: .quaternaryLabelColor.withAlphaComponent(0.12),
        quoteBar: .tertiaryLabelColor,
        chipBackground: .controlAccentColor.withAlphaComponent(0.12),
        checkbox: .controlAccentColor,
        keyword: .systemPink,
        string: .systemRed,
        comment: .secondaryLabelColor,
        number: .systemPurple,
        type: .systemTeal,
        attribute: .systemOrange,
        added: .systemGreen,
        removed: .systemRed
    )
}
