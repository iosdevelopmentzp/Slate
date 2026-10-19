import Foundation

package enum NoteSectionPolicy {
    package static func headings(in body: String) -> [String] {
        MarkdownText.proseLines(of: body).compactMap { line in
            SectionAppendPolicy.headingLevel(line.text) == nil ? nil : line.text
        }
    }

    package static func text(of heading: String, in body: String) -> String? {
        guard let bounds = bounds(of: heading, in: body) else { return nil }
        let lines = body.components(separatedBy: "\n")
        return lines[bounds].joined(separator: "\n").trimmingCharacters(in: .newlines)
    }

    package static func replacing(_ heading: String, with text: String, in body: String) -> String {
        guard let bounds = bounds(of: heading, in: body) else {
            return SectionAppendPolicy.append(text, toSection: heading, in: body)
        }
        var lines = body.components(separatedBy: "\n")
        let insertion = text.trimmingCharacters(in: .newlines)
        let atEnd = bounds.upperBound == lines.count
        var replacement = insertion.isEmpty ? [] : [""] + insertion.components(separatedBy: "\n")
        if atEnd == false {
            replacement.append("")
        }
        lines.replaceSubrange(bounds, with: replacement)
        let result = lines.joined(separator: "\n")
        return atEnd ? SectionAppendPolicy.trimmedEnd(result) + "\n" : result
    }

    package static func prepend(_ text: String, toSection heading: String?, in body: String) -> String {
        var lines = body.components(separatedBy: "\n")
        var bounds = 0..<lines.count
        if let heading {
            guard let found = self.bounds(of: heading, in: body) else {
                return SectionAppendPolicy.append(text, toSection: heading, in: body)
            }
            bounds = found
        }
        guard let first = bounds.first(where: { lines[$0].trimmingCharacters(in: .whitespaces).isEmpty == false }) else {
            return SectionAppendPolicy.append(text, toSection: heading, in: body)
        }
        let insertion = text.trimmingCharacters(in: .newlines).components(separatedBy: "\n")
        let joinsList = isListItem(insertion.last ?? "") && isListItem(lines[first])
        lines.insert(contentsOf: insertion + (joinsList ? [] : [""]), at: first)
        return lines.joined(separator: "\n")
    }

    static func bounds(of heading: String, in body: String) -> Range<Int>? {
        guard let start = SectionAppendPolicy.headingIndex(heading, in: body) else { return nil }
        let lines = body.components(separatedBy: "\n")
        return (start + 1)..<SectionAppendPolicy.sectionEnd(after: start, lines: lines, body: body)
    }

    private static func isListItem(_ line: String) -> Bool {
        line.range(of: #"^\s*(?:[-*+]|\d+[.)])\s"#, options: .regularExpression) != nil
    }
}
