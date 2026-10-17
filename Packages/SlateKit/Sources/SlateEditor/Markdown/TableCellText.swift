import Foundation
import Markdown

enum TableCellText {
    static func inline(_ markdown: String) -> NSAttributedString? {
        let trimmed = markdown.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false else { return NSAttributedString() }
        let document = Document(parsing: trimmed, options: [.disableSmartOpts])
        let children = Array(document.children)
        guard children.count == 1, let paragraph = children.first as? Paragraph else { return nil }
        return InlineReader.read(paragraph.children, source: SourceLines(lines: [trimmed]), allowsImages: true)
    }

    static func markdown(of text: NSAttributedString) -> String {
        InlineWriter.lines(of: text).joined(separator: " ")
    }

    static func isSupported(_ model: TableModel) -> Bool {
        model.allRows.joined().allSatisfy { inline($0.markdown) != nil }
    }
}
