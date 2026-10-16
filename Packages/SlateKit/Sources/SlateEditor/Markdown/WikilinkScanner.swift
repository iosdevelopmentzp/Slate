import Foundation

enum WikilinkScanner {

    static func expand(_ runs: [InlineRun]) -> [InlineRun] {
        runs.flatMap { run -> [InlineRun] in
            guard run.allowsWiki, run.href == nil, run.style.contains(.code) == false, run.text.contains("[[") else { return [run] }
            return split(run)
        }
    }

    static func split(_ run: InlineRun) -> [InlineRun] {
        var result: [InlineRun] = []
        var rest = Substring(run.text)
        while let open = rest.range(of: "[["), let close = rest[open.upperBound...].range(of: "]]") {
            let inner = rest[open.upperBound..<close.lowerBound]
            guard inner.isEmpty == false, inner.contains("[") == false, inner.contains("]") == false, inner.contains(RichText.lineBreak) == false else {
                result.append(InlineRun(text: String(rest[..<close.upperBound]), style: run.style))
                rest = rest[close.upperBound...]
                continue
            }
            if open.lowerBound > rest.startIndex {
                result.append(InlineRun(text: String(rest[..<open.lowerBound]), style: run.style))
            }
            let parts = inner.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
            let target = String(parts[0])
            let label = parts.count > 1 && parts[1].isEmpty == false ? String(parts[1]) : target
            result.append(InlineRun(text: label, style: run.style, href: RichText.wikiPrefix + target))
            rest = rest[close.upperBound...]
        }
        if rest.isEmpty == false {
            result.append(InlineRun(text: String(rest), style: run.style))
        }
        return mergePlain(result)
    }

    private static func mergePlain(_ runs: [InlineRun]) -> [InlineRun] {
        var merged: [InlineRun] = []
        for run in runs {
            if let last = merged.last, last.href == nil, run.href == nil, last.style == run.style, last.allowsWiki == run.allowsWiki {
                merged[merged.count - 1].text += run.text
            } else {
                merged.append(run)
            }
        }
        return merged
    }
}
