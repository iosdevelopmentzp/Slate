import Foundation

package enum SectionAppendPolicy {
    package static func append(_ text: String, toSection heading: String?, in body: String) -> String {
        let insertion = text.trimmingCharacters(in: .newlines)
        guard let heading else {
            let base = trimmedEnd(body)
            return base + (base.isEmpty ? "" : "\n\n") + insertion + "\n"
        }
        var lines = body.components(separatedBy: "\n")
        guard let start = headingIndex(heading, in: body) else {
            let base = trimmedEnd(body)
            return base + (base.isEmpty ? "" : "\n\n") + "## \(heading)\n\n" + insertion + "\n"
        }
        let end = sectionEnd(after: start, lines: lines, body: body)
        var last = end - 1
        while last > start, lines[last].trimmingCharacters(in: .whitespaces).isEmpty {
            last -= 1
        }
        let isFirst = last == start
        let atEnd = end == lines.count
        var replacement = isFirst ? [""] : []
        replacement += insertion.components(separatedBy: "\n")
        if atEnd == false {
            replacement.append("")
        }
        lines.replaceSubrange((last + 1)..<end, with: replacement)
        var result = lines.joined(separator: "\n")
        if atEnd {
            result = trimmedEnd(result) + "\n"
        }
        return result
    }

    package static func headingIndex(_ heading: String, in body: String) -> Int? {
        let wanted = heading.trimmingCharacters(in: .whitespaces).lowercased()
        for line in MarkdownText.proseLines(of: body) {
            guard headingLevel(line.text) != nil else { continue }
            let text = line.text.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces).lowercased()
            if text == wanted { return line.index }
        }
        return nil
    }

    static func sectionEnd(after start: Int, lines: [String], body: String) -> Int {
        let level = headingLevel(lines[start]) ?? 2
        let prose = Set(MarkdownText.proseLines(of: body).map(\.index))
        for index in (start + 1)..<lines.count where prose.contains(index) {
            if let other = headingLevel(lines[index]), other <= level {
                return index
            }
        }
        return lines.count
    }

    static func headingLevel(_ line: String) -> Int? {
        let hashes = line.prefix { $0 == "#" }.count
        guard (1...6).contains(hashes) else { return nil }
        let rest = line.dropFirst(hashes)
        guard rest.isEmpty || rest.first == " " else { return nil }
        return hashes
    }

    static func trimmedEnd(_ text: String) -> String {
        var result = text
        while result.hasSuffix("\n") || result.hasSuffix(" ") { result.removeLast() }
        return result
    }
}
