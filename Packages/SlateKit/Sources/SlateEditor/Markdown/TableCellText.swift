import Foundation
import Markdown

enum TableCellText {
    static func inline(_ markdown: String) -> NSAttributedString? {
        let trimmed = markdown.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false, trimmed.range(of: #"^(<br\s*/?>\s*)+$"#, options: [.regularExpression, .caseInsensitive]) == nil else { return NSAttributedString() }
        guard let paragraph = paragraph(of: trimmed) ?? paragraph(of: withoutBlockMarker(trimmed)) else { return nil }
        return InlineReader.read(paragraph.children, source: SourceLines(lines: [trimmed]), inCell: true)
    }

    private static func paragraph(of text: String) -> Paragraph? {
        let children = Array(Document(parsing: text, options: [.disableSmartOpts]).children)
        guard children.count == 1 else { return nil }
        return children.first as? Paragraph
    }

    private static func withoutBlockMarker(_ text: String) -> String {
        if let number = text.range(of: #"^\d+(?=[.)])"#, options: .regularExpression) {
            return text.replacingCharacters(in: number, with: text[number] + "\\")
        }
        return "\\" + text
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
