import Foundation

package enum TagPolicy {
    package static func inlineTags(in body: String) -> [String] {
        inlineTags(in: MarkdownText.proseLines(of: body))
    }

    package static func inlineTags(in lines: [MarkdownText.ProseLine]) -> [String] {
        var tags: [String] = []
        for line in lines where line.text.contains("#") {
            let ns = line.text as NSString
            for match in pattern.matches(in: line.text, range: NSRange(location: 0, length: ns.length)) where line.isInCode(match.range) == false {
                tags.append(ns.substring(with: match.range(at: 1)))
            }
        }
        return tags
    }

    package static func merged(header: [String]?, body: String) -> [String] {
        merged(header: header, lines: MarkdownText.proseLines(of: body))
    }

    package static func merged(header: [String]?, lines: [MarkdownText.ProseLine]) -> [String] {
        let all = (header ?? []).map(normalized) + inlineTags(in: lines)
        var seen = Set<String>()
        return all.filter { $0.isEmpty == false && seen.insert($0).inserted }.sorted()
    }

    package static func normalized(_ tag: String) -> String {
        var text = tag.trimmingCharacters(in: .whitespaces).lowercased()
        if text.hasPrefix("#") { text.removeFirst() }
        return text
    }

    package static func prefixMatches(_ tags: [String], prefix: String) -> [String] {
        let wanted = normalized(prefix)
        return tags.filter { wanted.isEmpty || $0.hasPrefix(wanted) }
    }

    private static let pattern = try! NSRegularExpression(pattern: #"(?<![\p{L}\p{N}_&/#])#([a-z0-9_/-]*[a-z][a-z0-9_/-]*)"#)
}
