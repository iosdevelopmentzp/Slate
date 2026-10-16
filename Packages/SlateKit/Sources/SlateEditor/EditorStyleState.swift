import Foundation

package struct EditorStyleState: Equatable, Sendable {
    package var kind: BlockKind
    package var inline: InlineStyle
    package var isLink: Bool
    package var canFormatText: Bool

    package init(kind: BlockKind = .body, inline: InlineStyle = [], isLink: Bool = false, canFormatText: Bool = true) {
        self.kind = kind
        self.inline = inline
        self.isLink = isLink
        self.canFormatText = canFormatText
    }
}
