import Foundation

nonisolated package struct TableCell: Hashable, Sendable {
    package var markdown: String

    package init(_ markdown: String = "") {
        self.markdown = markdown
    }

    package var isEmpty: Bool {
        markdown.allSatisfy(\.isWhitespace)
    }
}
