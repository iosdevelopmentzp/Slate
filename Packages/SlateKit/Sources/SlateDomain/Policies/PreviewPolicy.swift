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
        for (regex, template) in rules where regex.firstMatch(in: text, range: NSRange(location: 0, length: (text as NSString).length)) != nil {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(location: 0, length: (text as NSString).length), withTemplate: template)
        }
        return text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static let rules: [(NSRegularExpression, String)] = [
        (#"^#{1,6}\s+"#, ""),
        (#"^>\s?"#, ""),
        (#"^(?:[-*+]|\d+[.)])\s+(?:\[[ xX]\]\s*)?"#, ""),
        (#"!\[[^\]]*\]\([^)]*\)"#, ""),
        (#"\[\[([^\]|#]*)(?:#[^\]|]*)?\|([^\]]*)\]\]"#, "$2"),
        (#"\[\[([^\]|#]*)(?:#[^\]]*)?\]\]"#, "$1"),
        (#"\[([^\]]*)\]\([^)]*\)"#, "$1"),
        (#"</?(?:mark|span)(?:\s[^>]*)?>"#, ""),
        (#"==(?=\S)(.+?)(?<=\S)=="#, "$1"),
        (#"(\*\*|__|~~|`)"#, ""),
        (#"(?<![\w*])[*_](?=\S)|(?<=\S)[*_](?![\w*])"#, ""),
        (#"^(?:-{3,}|\*{3,}|_{3,})$"#, ""),
    ].map { (try! NSRegularExpression(pattern: $0.0), $0.1) }
}
