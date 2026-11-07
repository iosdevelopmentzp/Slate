import Foundation

enum BareURL {
    private static let pattern = try! NSRegularExpression(pattern: "https?://[^\\s<>\"'`\\[\\]|]+", options: [.caseInsensitive])
    private static let trailing = Set(".,;:!?*_~")
    private static let unsafe = Set("*`\\<>[]|~")

    static func ranges(in text: String) -> [NSRange] {
        let string = text as NSString
        return pattern.matches(in: text, range: NSRange(location: 0, length: string.length)).compactMap { match in
            let found = string.substring(with: match.range)
            let trimmed = trimmed(found)
            let length = (trimmed as NSString).length
            guard length > "https://".count else { return nil }
            return NSRange(location: match.range.location, length: length)
        }
    }

    static func isBare(_ href: String) -> Bool {
        guard href.contains(where: unsafe.contains) == false, href.contains("==") == false else { return false }
        return ranges(in: href) == [NSRange(location: 0, length: (href as NSString).length)]
    }

    static func expand(_ runs: [InlineRun]) -> [InlineRun] {
        runs.flatMap { run -> [InlineRun] in
            guard run.allowsWiki, run.href == nil, run.style.contains(.code) == false, run.text.contains("://") else { return [run] }
            return split(run)
        }
    }

    private static func split(_ run: InlineRun) -> [InlineRun] {
        let text = run.text as NSString
        var result: [InlineRun] = []
        var location = 0
        for range in ranges(in: run.text) {
            if range.location > location {
                result.append(InlineRun(text: text.substring(with: NSRange(location: location, length: range.location - location)), style: run.style, allowsWiki: true))
            }
            let url = text.substring(with: range)
            result.append(InlineRun(text: url, style: run.style, href: url, isBareURL: true))
            location = NSMaxRange(range)
        }
        guard result.isEmpty == false else { return [run] }
        if location < text.length {
            result.append(InlineRun(text: text.substring(from: location), style: run.style, allowsWiki: true))
        }
        return result
    }

    private static func trimmed(_ url: String) -> String {
        var url = Substring(url)
        while let last = url.last {
            if trailing.contains(last) {
                url = url.dropLast()
            } else if last == ")", url.filter({ $0 == "(" }).count < url.filter({ $0 == ")" }).count {
                url = url.dropLast()
            } else {
                break
            }
        }
        return String(url)
    }
}
