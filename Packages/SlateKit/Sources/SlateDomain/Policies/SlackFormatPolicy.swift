import Foundation

package enum SlackFormatPolicy {
    package static func format(_ markdown: String) -> String {
        var lines: [String] = []
        var inFence = false
        for line in markdown.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inFence.toggle()
                lines.append("```")
                continue
            }
            if inFence {
                lines.append(line)
                continue
            }
            lines.append(convert(line))
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .newlines)
    }

    private static func convert(_ line: String) -> String {
        var text = line
        let indent = String(text.prefix { $0 == " " })
        let rest = String(text.dropFirst(indent.count))
        if let heading = rest.range(of: #"^#{1,6}\s+"#, options: .regularExpression) {
            let inner = replaceInline(rest[heading.upperBound...].trimmingCharacters(in: .whitespaces))
            return indent + "*" + inner + "*"
        }
        if let box = rest.range(of: #"^[-*+]\s+\[[xX]\]\s+"#, options: .regularExpression) {
            text = indent + "☑︎ " + rest[box.upperBound...]
        } else if let box = rest.range(of: #"^[-*+]\s+\[ \]\s+"#, options: .regularExpression) {
            text = indent + "☐ " + rest[box.upperBound...]
        } else if let bullet = rest.range(of: #"^[-*+]\s+"#, options: .regularExpression) {
            text = indent + "• " + rest[bullet.upperBound...]
        }
        return replaceInline(text)
    }

    private static func replaceInline(_ line: String) -> String {
        var text = line
        let codes = MarkdownText.codeSpans(in: text)
        guard codes.isEmpty else {
            let ns = text as NSString
            var result = ""
            var cursor = 0
            for range in codes {
                result += replaceInline(ns.substring(with: NSRange(location: cursor, length: range.location - cursor)))
                result += ns.substring(with: range)
                cursor = range.upperBound
            }
            return result + replaceInline(ns.substring(from: cursor))
        }
        text = text.replacingOccurrences(of: #"\[\[([^\]|#]+)(?:#[^\]|]*)?\|([^\]]+)\]\]"#, with: "$2", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\[\[([^\]|#]+)(?:#[^\]]*)?\]\]"#, with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: #"!\[[^\]]*\]\(([^)]+)\)"#, with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\[([^\]]+)\]\(([^)]+)\)"#, with: "<$2|$1>", options: .regularExpression)
        text = text.replacingOccurrences(of: #"(?<![*\w])\*(?=[^\s*])([^*]+?)(?<=[^\s*])\*(?![*\w])"#, with: "_$1_", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\*\*(?=\S)(.+?)(?<=\S)\*\*"#, with: "*$1*", options: .regularExpression)
        text = text.replacingOccurrences(of: #"__(?=\S)(.+?)(?<=\S)__"#, with: "*$1*", options: .regularExpression)
        text = text.replacingOccurrences(of: #"~~(?=\S)(.+?)(?<=\S)~~"#, with: "~$1~", options: .regularExpression)
        return text
    }
}
