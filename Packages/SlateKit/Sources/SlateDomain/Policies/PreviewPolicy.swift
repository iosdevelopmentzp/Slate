import Foundation

package enum PreviewPolicy {
    package static let maxLength = 200

    package static func preview(of body: String) -> String {
        var parts: [String] = []
        var inFence = false
        var length = 0
        for rawLine in body.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                inFence.toggle()
                continue
            }
            guard inFence == false else { continue }
            let text = plainText(of: line)
            guard text.isEmpty == false else { continue }
            parts.append(text)
            length += text.count + 1
            if length > maxLength { break }
        }
        let joined = parts.joined(separator: " ")
        guard joined.count > maxLength else { return joined }
        return String(joined.prefix(maxLength)).trimmingCharacters(in: .whitespaces)
    }

    static func plainText(of line: String) -> String {
        var text = line
        text = replace(#"^#{1,6}\s+"#, in: text, with: "")
        text = replace(#"^>\s?"#, in: text, with: "")
        text = replace(#"^(?:[-*+]|\d+[.)])\s+(?:\[[ xX]\]\s*)?"#, in: text, with: "")
        text = replace(#"!\[[^\]]*\]\([^)]*\)"#, in: text, with: "")
        text = replace(#"\[\[([^\]|#]*)(?:#[^\]|]*)?\|([^\]]*)\]\]"#, in: text, with: "$2")
        text = replace(#"\[\[([^\]|#]*)(?:#[^\]]*)?\]\]"#, in: text, with: "$1")
        text = replace(#"\[([^\]]*)\]\([^)]*\)"#, in: text, with: "$1")
        text = replace(#"(\*\*|__|~~|`)"#, in: text, with: "")
        text = replace(#"(?<![\w*])[*_](?=\S)|(?<=\S)[*_](?![\w*])"#, in: text, with: "")
        text = replace(#"^(?:-{3,}|\*{3,}|_{3,})$"#, in: text, with: "")
        return text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static func replace(_ pattern: String, in text: String, with template: String) -> String {
        text.replacingOccurrences(of: pattern, with: template, options: .regularExpression)
    }
}
