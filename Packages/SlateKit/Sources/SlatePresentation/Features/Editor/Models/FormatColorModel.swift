import AppKit
import SlateEditor

struct FormatColorModel: Identifiable, Equatable {
    let id: String
    let title: String
    let swatch: NSColor?
    let command: EditorCommand
    let isCurrent: Bool

    static let preview = FormatColorModel(id: "highlight-yellow", title: "Yellow", swatch: HighlightColor.yellow.swatch, command: .highlight(.yellow), isCurrent: true)
}
