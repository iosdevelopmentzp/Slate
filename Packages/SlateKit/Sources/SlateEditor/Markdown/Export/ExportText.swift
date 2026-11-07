import Foundation
import Markdown

enum ExportText {
    private static let wikilink = try! NSRegularExpression(pattern: #"\[\[([^\[\]|]+?)(?:\|([^\[\]]+?))?\]\]"#)
    private static let highlight = try! NSRegularExpression(pattern: #"==(?=\S)(.+?)(?<=\S)=="#)
    private static let lineBreak = try! NSRegularExpression(pattern: #"^<br\s*/?>$"#, options: .caseInsensitive)

    static func clean(_ text: String) -> String {
        var result = replace(wikilink, in: text) { match, source in
            if match.range(at: 2).location != NSNotFound {
                return source.substring(with: match.range(at: 2))
            }
            let name = source.substring(with: match.range(at: 1))
            return name.components(separatedBy: "#").first ?? name
        }
        result = replace(highlight, in: result) { match, source in
            source.substring(with: match.range(at: 1))
        }
        return result
    }

    static func isLineBreak(_ html: String) -> Bool {
        let range = NSRange(html.startIndex..., in: html)
        return lineBreak.firstMatch(in: html, range: range) != nil
    }

    static func imageName(_ source: String) -> String {
        guard source.contains("://") == false else { return source }
        let path = source.removingPercentEncoding ?? source
        return (path as NSString).lastPathComponent
    }

    static func altText(_ image: Image) -> String {
        image.children.compactMap { ($0 as? Text)?.string }.joined()
    }

    static func codeText(_ block: CodeBlock) -> String {
        var code = block.code
        while code.hasSuffix("\n") { code.removeLast() }
        return code
    }

    static func cellText(_ cell: Table.Cell) -> String {
        var text = ""
        for child in cell.children {
            if let inline = child as? InlineHTML, isLineBreak(inline.rawHTML) {
                text += " "
            } else if child is InlineHTML == false, let plain = (child as? PlainTextConvertibleMarkup)?.plainText {
                text += plain
            }
        }
        return clean(text).trimmingCharacters(in: .whitespaces)
    }

    static func alignedTable(_ table: Table) -> String {
        var rows = [Array(table.head.cells).map(cellText)]
        rows += table.body.rows.map { Array($0.cells).map(cellText) }
        let count = rows.map(\.count).max() ?? 0
        let widths = (0..<count).map { column in
            rows.map { column < $0.count ? $0[column].count : 0 }.max() ?? 0
        }
        var lines = rows.map { row in
            (0..<count).map { column in
                let text = column < row.count ? row[column] : ""
                return text.padding(toLength: widths[column], withPad: " ", startingAt: 0)
            }
            .joined(separator: "  ")
            .trimmingCharacters(in: .whitespaces)
        }
        lines.insert(widths.map { String(repeating: "-", count: $0) }.joined(separator: "  "), at: 1)
        return lines.joined(separator: "\n")
    }

    private static func replace(_ regex: NSRegularExpression, in text: String, with transform: (NSTextCheckingResult, NSString) -> String) -> String {
        let source = text as NSString
        var result = ""
        var last = 0
        for match in regex.matches(in: text, range: NSRange(location: 0, length: source.length)) {
            result += source.substring(with: NSRange(location: last, length: match.range.location - last))
            result += transform(match, source)
            last = match.range.location + match.range.length
        }
        result += source.substring(from: last)
        return result
    }
}
