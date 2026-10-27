import Foundation

package enum ImagePlacementPolicy {
    package static func insert(_ image: String, after anchor: String, in body: String) throws -> String {
        let wanted = anchor.trimmingCharacters(in: .whitespacesAndNewlines)
        guard wanted.isEmpty == false else { throw AgentError.missingArgument("after") }
        var lines = body.components(separatedBy: "\n")
        let prose = MarkdownText.proseLines(of: body).map(\.index)
        let matches = prose.filter { lines[$0].contains(wanted) }
        guard let line = matches.first else { throw AgentError.textNotFound }
        guard matches.count == 1 else { throw AgentError.textNotUnique(matches.count) }
        let last = paragraphEnd(from: line, lines: lines, prose: Set(prose))
        let indent = String(repeating: " ", count: itemContentStart(of: line, lines: lines) ?? 0)
        var insertion = ["", indent + image.trimmingCharacters(in: .whitespacesAndNewlines)]
        if last + 1 < lines.count, isBlank(lines[last + 1]) == false {
            insertion.append("")
        }
        lines.insert(contentsOf: insertion, at: last + 1)
        return lines.joined(separator: "\n")
    }

    private static func paragraphEnd(from line: Int, lines: [String], prose: Set<Int>) -> Int {
        guard SectionAppendPolicy.headingLevel(lines[line]) == nil else { return line }
        var last = line
        while last + 1 < lines.count, prose.contains(last + 1) {
            let next = lines[last + 1]
            guard isBlank(next) == false, NoteSectionPolicy.isListItem(next) == false, SectionAppendPolicy.headingLevel(next) == nil else { break }
            last += 1
        }
        return last
    }

    private static func itemContentStart(of line: Int, lines: [String]) -> Int? {
        var index = line
        while index >= 0, isBlank(lines[index]) == false {
            if let start = contentStart(lines[index]) { return start }
            index -= 1
        }
        return nil
    }

    private static func contentStart(_ line: String) -> Int? {
        guard let match = line.range(of: #"^\s*(?:[-*+]|\d+[.)]) "#, options: .regularExpression) else { return nil }
        return line.distance(from: line.startIndex, to: match.upperBound)
    }

    private static func isBlank(_ line: String) -> Bool {
        line.allSatisfy { $0 == " " || $0 == "\t" }
    }
}
