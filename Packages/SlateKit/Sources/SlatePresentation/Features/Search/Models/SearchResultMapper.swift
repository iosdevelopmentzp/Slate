import Foundation
import SlateDomain
import SlateUI

enum SearchResultMapper {
    static func model(for hit: SearchHit, words: [String], now: Date) -> SearchResultRowModel {
        let summary = hit.summary
        return SearchResultRowModel(
            id: summary.id,
            title: highlighted(summary.title, words: words),
            excerpt: highlighted(hit.excerpt, words: words),
            folder: summary.space?.rawValue,
            date: summary.updated.relativeDescription(to: now)
        )
    }

    static func highlighted(_ text: String, words: [String]) -> AttributedString {
        let ns = text as NSString
        var result = AttributedString()
        var cursor = 0
        for range in SearchHighlightPolicy.ranges(of: words, in: text) {
            if range.location > cursor {
                result += AttributedString(ns.substring(with: NSRange(location: cursor, length: range.location - cursor)))
            }
            var match = AttributedString(ns.substring(with: range))
            match.inlinePresentationIntent = .stronglyEmphasized
            result += match
            cursor = range.upperBound
        }
        if cursor < ns.length {
            result += AttributedString(ns.substring(from: cursor))
        }
        return result
    }
}
