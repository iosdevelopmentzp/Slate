import Foundation

package enum EditorCommand: Hashable, Sendable {
    case style(BlockKind)
    case list(BlockKind)
    case quote
    case callout(String)
    case inline(InlineStyle)
    case highlight(HighlightColor?)
    case textColor(TextColor?)
    case link
    case image
    case file
    case divider
    case screenshot
    case simulatorScreenshot
    case indent(Int)
    case table
    case formatJSON
    case outline
    case findInNote
    case collapseSection
    case expandSection
    case collapseAllSections
    case expandAllSections
}
