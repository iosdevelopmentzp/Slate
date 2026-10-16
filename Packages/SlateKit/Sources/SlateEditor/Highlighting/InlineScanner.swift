import Foundation

struct InlineScanner {
    let patterns: [CompiledLinkPattern]

    init(patterns: [CompiledLinkPattern] = []) {
        self.patterns = patterns
    }

    func spans(in line: String) -> [InlineSpan] {
        let text = line as NSString
        let whole = NSRange(location: 0, length: text.length)
        guard whole.length > 0 else { return [] }
        var spans: [InlineSpan] = []
        var occupied = IndexSet()

        func free(_ range: NSRange) -> Bool {
            occupied.intersects(integersIn: range.location..<range.upperBound) == false
        }

        func occupy(_ range: NSRange) {
            occupied.insert(integersIn: range.location..<range.upperBound)
        }

        if line.contains("`") {
            for match in Self.codeSpan.matches(in: line, range: whole) {
                let fence = match.range(at: 1).length
                spans.append(InlineSpan(range: NSRange(location: match.range.location, length: fence), kind: .mark))
                spans.append(InlineSpan(range: match.range(at: 2), kind: .code))
                spans.append(InlineSpan(range: NSRange(location: match.range.upperBound - fence, length: fence), kind: .mark))
                occupy(match.range)
            }
        }
        if line.contains("[[") {
            for match in Self.wikilink.matches(in: line, range: whole) where free(match.range) {
                let inner = text.substring(with: match.range(at: 1))
                let target = String(inner.split(separator: "|", maxSplits: 1).first ?? "")
                spans.append(InlineSpan(range: NSRange(location: match.range.location, length: 2), kind: .mark))
                spans.append(InlineSpan(range: match.range(at: 1), kind: .wikilink(target.trimmingCharacters(in: .whitespaces))))
                spans.append(InlineSpan(range: NSRange(location: match.range.upperBound - 2, length: 2), kind: .mark))
                occupy(match.range)
            }
        }
        if line.contains("](") {
            for match in Self.link.matches(in: line, range: whole) where free(match.range) {
                let label = match.range(at: 1)
                let target = match.range(at: 2)
                let url = text.substring(with: target)
                spans.append(InlineSpan(range: NSRange(location: match.range.location, length: label.location - match.range.location), kind: .mark))
                spans.append(InlineSpan(range: label, kind: .link(url)))
                spans.append(InlineSpan(range: NSRange(location: label.upperBound, length: match.range.upperBound - label.upperBound), kind: .mark))
                occupy(NSRange(location: label.upperBound, length: match.range.upperBound - label.upperBound))
            }
        }
        if line.contains("://") {
            for match in Self.url.matches(in: line, range: whole) where free(match.range) {
                spans.append(InlineSpan(range: match.range, kind: .url(text.substring(with: match.range))))
                occupy(match.range)
            }
        }
        for pattern in patterns {
            for match in pattern.regex.matches(in: line, range: whole) where match.range.length > 0 && free(match.range) {
                spans.append(InlineSpan(range: match.range, kind: .pattern(id: pattern.id, match: text.substring(with: match.range))))
                occupy(match.range)
            }
        }
        if line.contains("#") {
            for match in Self.tag.matches(in: line, range: whole) where free(match.range) {
                spans.append(InlineSpan(range: match.range, kind: .tag(text.substring(with: match.range(at: 1)))))
            }
        }
        if line.contains("*") || line.contains("_") {
            appendDelimited(Self.strong, kind: .strong, markLength: 2, in: line, whole: whole, to: &spans, free: free)
            appendDelimited(Self.starEmphasis, kind: .emphasis, markLength: 1, in: line, whole: whole, to: &spans, free: free)
            appendDelimited(Self.underscoreEmphasis, kind: .emphasis, markLength: 1, in: line, whole: whole, to: &spans, free: free)
        }
        if line.contains("~~") {
            appendDelimited(Self.strike, kind: .strike, markLength: 2, in: line, whole: whole, to: &spans, free: free)
        }
        return spans
    }

    private func appendDelimited(_ regex: NSRegularExpression, kind: InlineSpan.Kind, markLength: Int, in line: String, whole: NSRange, to spans: inout [InlineSpan], free: (NSRange) -> Bool) {
        for match in regex.matches(in: line, range: whole) where free(match.range) {
            let range = match.range
            spans.append(InlineSpan(range: range, kind: kind))
            spans.append(InlineSpan(range: NSRange(location: range.location, length: markLength), kind: .mark))
            spans.append(InlineSpan(range: NSRange(location: range.upperBound - markLength, length: markLength), kind: .mark))
        }
    }

    private static let codeSpan = try! NSRegularExpression(pattern: #"(`+)(.+?)\1"#)
    private static let wikilink = try! NSRegularExpression(pattern: #"\[\[([^\[\]\n]+?)\]\]"#)
    private static let link = try! NSRegularExpression(pattern: #"!?\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)"#)
    private static let url = try! NSRegularExpression(pattern: #"\bhttps?://[^\s<>()\[\]]*[^\s<>()\[\].,;:!?'"]"#)
    private static let tag = try! NSRegularExpression(pattern: #"(?<![\p{L}\p{N}_&/#])#([a-z0-9_/-]*[a-z][a-z0-9_/-]*)"#)
    private static let strong = try! NSRegularExpression(pattern: #"(\*\*|__)(?=\S)(.+?)(?<=\S)\1"#)
    private static let starEmphasis = try! NSRegularExpression(pattern: #"(?<![*\\])\*(?=[^\s*])([^*]+?)(?<=[^\s*])\*(?!\*)"#)
    private static let underscoreEmphasis = try! NSRegularExpression(pattern: #"(?<![_\p{L}\p{N}])_(?=[^\s_])([^_]+?)(?<=[^\s_])_(?![_\p{L}\p{N}])"#)
    private static let strike = try! NSRegularExpression(pattern: #"~~(?=\S)(.+?)(?<=\S)~~"#)
}
