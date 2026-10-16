import Foundation

enum MarkdownLineScanner {
    static func kind(of line: String) -> LineKind {
        guard line.contains(where: { $0.isWhitespace == false }) else { return .blank }
        if let heading = heading(line) { return heading }
        if isRule(line) { return .rule }
        if let item = listItem(line) { return .listItem(item) }
        if line.hasPrefix(">") {
            let markLength = line.hasPrefix("> ") ? 2 : 1
            return .quote(markLength: markLength)
        }
        if let image = image(line) { return image }
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("|") { return .tableRow }
        return .paragraph
    }

    private static func heading(_ line: String) -> LineKind? {
        let hashes = line.prefix { $0 == "#" }
        guard (1...6).contains(hashes.count) else { return nil }
        let rest = line.dropFirst(hashes.count)
        guard rest.isEmpty || rest.first == " " else { return nil }
        let markLength = hashes.count + (rest.isEmpty ? 0 : 1)
        return .heading(level: hashes.count, markLength: markLength)
    }

    private static func isRule(_ line: String) -> Bool {
        let compact = line.filter { $0 != " " }
        guard compact.count >= 3, let first = compact.first, "-*_".contains(first) else { return false }
        return compact.allSatisfy { $0 == first }
    }

    static func listItem(_ line: String) -> ListItem? {
        let characters = Array(line.utf16)
        var index = 0
        while index < characters.count, characters[index] == 0x20 || characters[index] == 0x09 {
            index += 1
        }
        let indent = index
        guard index < characters.count else { return nil }
        let marker: ListItem.Marker
        let markerStart = index
        let first = characters[index]
        if first == 0x2D || first == 0x2A || first == 0x2B {
            marker = .bullet(Character(UnicodeScalar(first)!))
            index += 1
        } else {
            var digits = 0
            var number = 0
            while index < characters.count, (0x30...0x39).contains(characters[index]), digits < 9 {
                number = number * 10 + Int(characters[index] - 0x30)
                index += 1
                digits += 1
            }
            guard digits > 0, index < characters.count, characters[index] == 0x2E || characters[index] == 0x29 else { return nil }
            marker = .ordered(number: number, delimiter: Character(UnicodeScalar(characters[index])!))
            index += 1
        }
        let markerLength = index - markerStart
        if index == characters.count {
            return ListItem(indent: indent, marker: marker, markerLength: markerLength, contentStart: index, checkbox: nil)
        }
        guard characters[index] == 0x20 else { return nil }
        index += 1
        let box = checkbox(in: characters, at: index)
        let contentStart = box.map { min($0.range.upperBound + 1, characters.count) } ?? index
        return ListItem(indent: indent, marker: marker, markerLength: markerLength, contentStart: contentStart, checkbox: box)
    }

    private static func checkbox(in characters: [UInt16], at index: Int) -> ListItem.Checkbox? {
        guard index + 3 <= characters.count, characters[index] == 0x5B, characters[index + 2] == 0x5D else { return nil }
        let mark = characters[index + 1]
        let followedBySpace = index + 3 == characters.count || characters[index + 3] == 0x20
        guard followedBySpace, mark == 0x20 || mark == 0x78 || mark == 0x58 else { return nil }
        return ListItem.Checkbox(isChecked: mark != 0x20, range: NSRange(location: index, length: 3))
    }

    private static func image(_ line: String) -> LineKind? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("!["), trimmed.hasSuffix(")") else { return nil }
        let nsLine = line as NSString
        guard let match = imagePattern.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) else { return nil }
        let sourceRange = match.range(at: 1)
        return .image(source: nsLine.substring(with: sourceRange), sourceRange: sourceRange)
    }

    private static let imagePattern = try! NSRegularExpression(pattern: #"^\s*!\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)\s*$"#)
}
