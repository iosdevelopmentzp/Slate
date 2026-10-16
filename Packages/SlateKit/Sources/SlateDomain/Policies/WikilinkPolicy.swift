import Foundation

package enum WikilinkPolicy {
    package struct Target: Hashable, Sendable {
        package let space: String?
        package let stem: String
        package let heading: String?

        package init(space: String?, stem: String, heading: String?) {
            self.space = space
            self.stem = stem
            self.heading = heading
        }
    }

    package static func targets(in body: String) -> [String] {
        targets(in: MarkdownText.proseLines(of: body))
    }

    package static func targets(in lines: [MarkdownText.ProseLine]) -> [String] {
        var result: [String] = []
        for line in lines where line.text.contains("[[") {
            let ns = line.text as NSString
            for match in pattern.matches(in: line.text, range: NSRange(location: 0, length: ns.length)) where line.isInCode(match.range) == false {
                let target = parse(ns.substring(with: match.range(at: 1)))
                let name = target.space.map { "\($0)/\(target.stem)" } ?? target.stem
                if name.isEmpty == false { result.append(name) }
            }
        }
        return result
    }

    package static func parse(_ inner: String) -> Target {
        let beforeAlias = inner.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? inner
        let parts = beforeAlias.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        let name = parts[0].trimmingCharacters(in: .whitespaces)
        let heading = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : nil
        let pieces = name.split(separator: "/", maxSplits: 1).map(String.init)
        if pieces.count == 2 {
            return Target(space: pieces[0], stem: pieces[1], heading: heading)
        }
        return Target(space: nil, stem: name, heading: heading)
    }

    package static func rewrite(_ body: String, from oldStem: String, to newStem: String) -> String {
        guard body.contains("[[") else { return body }
        var lines = body.components(separatedBy: "\n")
        for line in MarkdownText.proseLines(of: body) where line.text.contains("[[") {
            let ns = line.text as NSString
            var replaced = line.text
            for match in pattern.matches(in: line.text, range: NSRange(location: 0, length: ns.length)).reversed() where line.isInCode(match.range) == false {
                let innerRange = match.range(at: 1)
                let inner = ns.substring(with: innerRange)
                guard let rewritten = rewriteInner(inner, from: oldStem, to: newStem) else { continue }
                replaced = (replaced as NSString).replacingCharacters(in: innerRange, with: rewritten)
            }
            lines[line.index] = replaced
        }
        return lines.joined(separator: "\n")
    }

    package static func resolve(_ name: String, candidates: [NoteSummary], from source: VaultPath?) -> NoteSummary? {
        let target = parse(name)
        let matching = candidates.filter { summary in
            guard StemPolicy.isSame(summary.stem, target.stem) else { return false }
            guard let space = target.space else { return true }
            return summary.space.map { StemPolicy.isSame($0.rawValue, space) } ?? false
        }
        let space = source?.space
        return matching.max { lhs, rhs in
            let left = (lhs.space == space ? 1 : 0, lhs.updated)
            let right = (rhs.space == space ? 1 : 0, rhs.updated)
            return left < right
        }
    }

    private static func rewriteInner(_ inner: String, from oldStem: String, to newStem: String) -> String? {
        let pipe = inner.firstIndex(of: "|")
        let beforeAlias = pipe.map { String(inner[..<$0]) } ?? inner
        let alias = pipe.map { String(inner[$0...]) } ?? ""
        let hash = beforeAlias.firstIndex(of: "#")
        let name = hash.map { String(beforeAlias[..<$0]) } ?? beforeAlias
        let heading = hash.map { String(beforeAlias[$0...]) } ?? ""
        let slash = name.firstIndex(of: "/")
        let spacePart = slash.map { String(name[...$0]) } ?? ""
        let stem = slash.map { String(name[name.index(after: $0)...]) } ?? name
        guard StemPolicy.isSame(stem.trimmingCharacters(in: .whitespaces), oldStem) else { return nil }
        return spacePart + newStem + heading + alias
    }

    private static let pattern = try! NSRegularExpression(pattern: #"\[\[([^\[\]\n]+?)\]\]"#)
}
