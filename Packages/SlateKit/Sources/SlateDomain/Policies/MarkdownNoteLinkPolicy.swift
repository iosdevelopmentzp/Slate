import Foundation

package enum MarkdownNoteLinkPolicy {
    private static let pattern = try! NSRegularExpression(pattern: #"(?<!!)\[[^\]]*\]\(\s*<?([^()<>\s]+?\.md|[^()<>]+?\.md)>?\s*\)"#)

    package static func targets(in lines: [MarkdownText.ProseLine]) -> [String] {
        var result: [String] = []
        for line in lines where line.text.contains(".md") {
            let ns = line.text as NSString
            for match in pattern.matches(in: line.text, range: NSRange(location: 0, length: ns.length)) where line.isInCode(match.range) == false {
                if let stem = stem(of: ns.substring(with: match.range(at: 1))) { result.append(stem) }
            }
        }
        return result
    }

    package static func stem(of destination: String) -> String? {
        let trimmed = destination.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("://") == false, trimmed.lowercased().hasPrefix("mailto:") == false else { return nil }
        let decoded = trimmed.removingPercentEncoding ?? trimmed
        let name = decoded.split(separator: "/").last.map(String.init) ?? decoded
        guard name.lowercased().hasSuffix(".md") else { return nil }
        let stem = String(name.dropLast(3))
        return stem.isEmpty ? nil : stem
    }

    package static func mentions(_ line: MarkdownText.ProseLine, stem: String) -> Bool {
        let wiki = WikilinkPolicy.targets(in: [line]).contains { StemPolicy.isSame(WikilinkPolicy.parse($0).stem, stem) }
        return wiki || targets(in: [line]).contains { StemPolicy.isSame($0, stem) }
    }
}
