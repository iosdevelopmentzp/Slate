import Foundation

nonisolated enum DiagramSource {
    static let fence = "mermaid"

    static func isDiagram(_ block: BlockAttributes) -> Bool {
        block.kind == .monospaced && block.language?.lowercased() == fence
    }

    static func text(of paragraph: String) -> String {
        paragraph
            .trimmingCharacters(in: .newlines)
            .replacingOccurrences(of: RichText.lineBreakString, with: "\n")
    }
}
