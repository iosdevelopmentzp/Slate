import Foundation

package enum QuestionPolicy {
    private static let marker = try! NSRegularExpression(pattern: #"^>\s?\[!question\]([+-]?)\s*(.*)$"#, options: .caseInsensitive)

    package static func open(in body: String) -> [OpenQuestion] {
        callouts(in: body.components(separatedBy: "\n")).enumerated().map { offset, callout in
            OpenQuestion(number: offset + 1, title: callout.title, text: callout.text, line: callout.start + 1)
        }
    }

    package static func answering(_ number: Int, with answer: String, in body: String) throws -> String {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { throw AgentError.missingArgument("answer") }
        var lines = body.components(separatedBy: "\n")
        let found = callouts(in: lines)
        guard number >= 1, number <= found.count else { throw AgentError.noQuestion(number, open: found.count) }
        let callout = found[number - 1]
        lines[callout.start] = lines[callout.start].replacingOccurrences(of: "[!question]", with: "[!ANSWER]", options: .caseInsensitive)
        let answerLines = trimmed.components(separatedBy: "\n").enumerated().map { offset, line in
            let text = offset == 0 ? "**Answer:** " + line : line
            return text.isEmpty ? ">" : "> " + text
        }
        lines.insert(contentsOf: [">"] + answerLines, at: callout.end)
        return lines.joined(separator: "\n")
    }

    private static func callouts(in lines: [String]) -> [(start: Int, end: Int, title: String, text: String)] {
        var result: [(start: Int, end: Int, title: String, text: String)] = []
        var fence: String?
        var index = 0
        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let open = fence {
                if trimmed.hasPrefix(open) { fence = nil }
                index += 1
                continue
            }
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                fence = String(trimmed.prefix(3))
                index += 1
                continue
            }
            guard let match = marker.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)), let titleRange = Range(match.range(at: 2), in: line) else {
                index += 1
                continue
            }
            let start = index
            index += 1
            var text: [String] = []
            while index < lines.count, lines[index].hasPrefix(">") {
                let content = lines[index].dropFirst().trimmingCharacters(in: .whitespaces)
                if content.isEmpty == false { text.append(content) }
                index += 1
            }
            result.append((start, index, String(line[titleRange]).trimmingCharacters(in: .whitespaces), text.joined(separator: "\n")))
        }
        return result
    }
}
