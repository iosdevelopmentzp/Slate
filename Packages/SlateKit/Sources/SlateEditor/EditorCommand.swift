import Foundation

package enum EditorCommand: Hashable, Sendable {
    case style(BlockKind)
    case list(BlockKind)
    case quote
    case inline(InlineStyle)
    case link
    case image
    case file
    case divider
    case screenshot
    case indent(Int)
    case table
}
