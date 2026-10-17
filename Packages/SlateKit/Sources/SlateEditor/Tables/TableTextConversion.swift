import Foundation

enum TableTextConversion {
    enum Separator {
        case tab
        case pipe
        case none
    }

    struct Line {
        let text: NSAttributedString
        let images: [(path: String, alt: String?)]
    }

    static func model(from paragraphs: [NSAttributedString]) -> TableModel? {
        let lines = paragraphs.filter { $0.string.trimmingCharacters(in: .whitespaces).isEmpty == false }
        guard lines.isEmpty == false else { return nil }
        let separator = separator(for: lines.map(\.string))
        let rows = lines
            .filter { separator != .pipe || isDelimiterRow($0.string) == false }
            .map { cells(of: $0, separator: separator) }
        guard let first = rows.first else { return nil }
        let width = rows.map(\.count).max() ?? first.count
        let table = rows.map { row in
            (row + Array(repeating: NSAttributedString(), count: width - row.count)).map { TableCell(TableCellText.markdown(of: trimmed($0))) }
        }
        let body = table.count > 1 ? Array(table.dropFirst()) : [Array(repeating: TableCell(), count: width)]
        return TableModel(columns: Array(repeating: TableColumn(), count: width), header: table[0], rows: body)
    }

    static func lines(of model: TableModel) -> [Line] {
        model.allRows.map { row in
            let text = NSMutableAttributedString()
            var images: [(path: String, alt: String?)] = []
            for (column, cell) in row.enumerated() {
                if column > 0 {
                    text.append(NSAttributedString(string: "\t"))
                }
                let inline = NSMutableAttributedString(attributedString: TableCellText.inline(cell.markdown) ?? NSAttributedString(string: cell.markdown))
                inline.enumerateAttribute(.slateImagePath, in: NSRange(location: 0, length: inline.length), options: .reverse) { value, range, _ in
                    guard let path = value as? String else { return }
                    images.insert((path, inline.attribute(.slateImageAlt, at: range.location, effectiveRange: nil) as? String), at: 0)
                    inline.deleteCharacters(in: range)
                }
                text.append(trimmed(inline))
            }
            return Line(text: text, images: images)
        }
    }

    static func separator(for lines: [String]) -> Separator {
        if lines.contains(where: { $0.contains("\t") }) { return .tab }
        if lines.allSatisfy({ $0.contains("|") }) { return .pipe }
        return .none
    }

    private static func cells(of line: NSAttributedString, separator: Separator) -> [NSAttributedString] {
        let string = line.string as NSString
        var marks: [Int] = []
        for index in 0..<string.length {
            let character = string.character(at: index)
            switch separator {
            case .tab where character == 0x09:
                marks.append(index)
            case .pipe where character == 0x7C && (index == 0 || string.character(at: index - 1) != 0x5C):
                marks.append(index)
            default:
                continue
            }
        }
        var pieces: [NSAttributedString] = []
        var start = 0
        for mark in marks + [string.length] {
            pieces.append(line.attributedSubstring(from: NSRange(location: start, length: mark - start)))
            start = mark + 1
        }
        let outer = line.string.trimmingCharacters(in: .whitespaces)
        guard separator == .pipe, pieces.count > 1 else { return pieces }
        if outer.hasPrefix("|") {
            pieces.removeFirst()
        }
        if outer.hasSuffix("|"), pieces.isEmpty == false {
            pieces.removeLast()
        }
        return pieces
    }

    private static func isDelimiterRow(_ line: String) -> Bool {
        line.range(of: #"^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$"#, options: .regularExpression) != nil
    }

    private static func trimmed(_ text: NSAttributedString) -> NSAttributedString {
        let string = text.string as NSString
        var start = 0
        var end = string.length
        let spaces = CharacterSet.whitespaces
        while start < end, let scalar = UnicodeScalar(string.character(at: start)), spaces.contains(scalar) { start += 1 }
        while end > start, let scalar = UnicodeScalar(string.character(at: end - 1)), spaces.contains(scalar) { end -= 1 }
        return text.attributedSubstring(from: NSRange(location: start, length: end - start))
    }
}
