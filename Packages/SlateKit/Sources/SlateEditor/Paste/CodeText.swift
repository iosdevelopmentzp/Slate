import Foundation

enum CodeText {
    struct Block: Equatable {
        let code: String
        let language: String?
    }

    private static let lineEnds: Set<Character> = ["{", "}", "[", "]", "(", ")", ";", ","]
    private static let lineStarts: Set<Character> = ["}", "]", ")", "<", "\"", "#", "@"]
    private static let codeMarks: Set<Character> = ["{", "}", "(", ")", ";", "=", "<", ">", "[", "]"]

    static func block(from text: String) -> Block? {
        let normalized = trimmingBlankLines(text.replacingOccurrences(of: "\r\n", with: "\n"), leading: false)
        let trimmed = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        if isJSON(trimmed) {
            return Block(code: trimmed.contains("\n") ? trimmingBlankLines(normalized, leading: true) : prettyJSON(trimmed), language: "json")
        }
        return looksLikeCode(normalized) ? Block(code: trimmingBlankLines(normalized, leading: true), language: nil) : nil
    }

    static func formattedJSON(_ text: String) -> String? {
        let plain = text
            .replacingOccurrences(of: RichText.lineBreakString, with: "\n")
            .replacingOccurrences(of: RichText.attachmentString, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return isJSON(plain) ? prettyJSON(plain) : nil
    }

    static func isJSON(_ text: String) -> Bool {
        guard let first = text.first, first == "{" || first == "[", let data = text.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    static func looksLikeCode(_ text: String) -> Bool {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true).filter { $0.allSatisfy(\.isWhitespace) == false }
        guard lines.count >= 3, text.contains(where: { codeMarks.contains($0) }) else { return false }
        let codeLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("  ") || line.hasPrefix("\t") { return true }
            if let last = trimmed.last, lineEnds.contains(last) { return true }
            if let first = trimmed.first, lineStarts.contains(first) { return true }
            return trimmed.hasPrefix("//")
        }
        return Double(codeLines.count) >= Double(lines.count) * 0.6
    }

    static func prettyJSON(_ text: String) -> String {
        var result = ""
        var depth = 0
        var inString = false
        var escaped = false
        let characters = Array(text)
        var index = 0
        func newline() {
            result.append("\n")
            result.append(String(repeating: "  ", count: depth))
        }
        func nextNonSpace(after position: Int) -> Character? {
            characters[(position + 1)...].first { $0.isWhitespace == false }
        }
        while index < characters.count {
            let character = characters[index]
            defer { index += 1 }
            if inString {
                result.append(character)
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
                continue
            }
            switch character {
            case "\"":
                inString = true
                result.append(character)
            case "{", "[":
                result.append(character)
                if let next = nextNonSpace(after: index), next == "}" || next == "]" { continue }
                depth += 1
                newline()
            case "}", "]":
                if let last = result.last, last != "{", last != "[" {
                    depth = max(depth - 1, 0)
                    newline()
                }
                result.append(character)
            case ",":
                result.append(character)
                newline()
            case ":":
                result.append(": ")
            default:
                if character.isWhitespace == false { result.append(character) }
            }
        }
        return result
    }

    private static func trimmingBlankLines(_ text: String, leading: Bool) -> String {
        var lines = text.components(separatedBy: "\n")
        if leading {
            while let first = lines.first, first.allSatisfy(\.isWhitespace) { lines.removeFirst() }
        } else {
            while let last = lines.last, last.allSatisfy(\.isWhitespace) { lines.removeLast() }
        }
        return lines.joined(separator: "\n")
    }
}
