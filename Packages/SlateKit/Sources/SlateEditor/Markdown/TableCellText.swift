import Foundation
import Markdown

enum TableCellText {
    static func inline(_ markdown: String) -> NSAttributedString? {
        let trimmed = markdown.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false, trimmed.range(of: #"^(<br\s*/?>\s*)+$"#, options: [.regularExpression, .caseInsensitive]) == nil else { return NSAttributedString() }
        let document = Document(parsing: trimmed, options: [.disableSmartOpts])
        let children = Array(document.children)
        guard children.count == 1, let paragraph = children.first as? Paragraph else { return nil }
        return InlineReader.read(paragraph.children, source: SourceLines(lines: [trimmed]), inCell: true)
    }

    static let lineBreakTag = "<br>"

    static func markdown(of text: NSAttributedString) -> String {
        var lines = InlineWriter.lines(of: text)
        while lines.first?.isEmpty == true { lines.removeFirst() }
        while lines.last?.isEmpty == true { lines.removeLast() }
        return lines.joined(separator: lineBreakTag)
    }

    static func isSupported(_ model: TableModel) -> Bool {
        model.allRows.joined().allSatisfy { inline($0.markdown) != nil }
    }
}
