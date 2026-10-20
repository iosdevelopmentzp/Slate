import Foundation

package enum ExportMarkdownPolicy {
    private static let wikilink = try! NSRegularExpression(pattern: #"\[\[([^\[\]]+)\]\]"#)
    private static let highlight = try! NSRegularExpression(pattern: #"(?<![=\\])==(?=[^\s=])(.+?)(?<=[^\s=\\])==(?!=)"#)

    package static func prepared(_ body: String) -> String {
        var lines = body.components(separatedBy: "\n")
        for line in MarkdownText.proseLines(of: body) where line.text.contains("[[") || line.text.contains("==") {
            var text = line.text
            text = replacing(wikilink, in: text, codeSpans: line.codeSpans) { inner in
                let parts = inner.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
                let label = parts.count > 1 ? String(parts[1]) : WikilinkPolicy.parse(inner).stem
                return label.isEmpty ? inner : label
            }
            text = replacing(highlight, in: text, codeSpans: MarkdownText.proseLines(of: text).first?.codeSpans ?? []) { "<mark>\($0)</mark>" }
            lines[line.index] = text
        }
        return lines.joined(separator: "\n")
    }

    private static func replacing(_ regex: NSRegularExpression, in text: String, codeSpans: [NSRange], with transform: (String) -> String) -> String {
        let ns = text as NSString
        var result = text
        for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            guard codeSpans.contains(where: { NSIntersectionRange($0, match.range).length > 0 }) == false else { continue }
            result = (result as NSString).replacingCharacters(in: match.range, with: transform(ns.substring(with: match.range(at: 1))))
        }
        return result
    }
}
