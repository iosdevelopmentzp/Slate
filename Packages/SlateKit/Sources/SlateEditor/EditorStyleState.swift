import Foundation

package struct EditorStyleState: Equatable, Sendable {
    package var kind: BlockKind
    package var inline: InlineStyle
    package var isLink: Bool
    package var canFormatText: Bool
    package var isInCell: Bool

    package init(kind: BlockKind = .body, inline: InlineStyle = [], isLink: Bool = false, canFormatText: Bool = true, isInCell: Bool = false) {
        self.kind = kind
        self.inline = inline
        self.isLink = isLink
        self.canFormatText = canFormatText
        self.isInCell = isInCell
    }

    package var highlight: HighlightColor? {
        inline.highlight
    }

    package var textColor: TextColor? {
        inline.textColor
    }

    package var canFormatInline: Bool {
        canFormatText || isInCell
    }
}
