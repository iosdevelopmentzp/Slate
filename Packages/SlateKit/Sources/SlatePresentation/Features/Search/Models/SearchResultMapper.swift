import Foundation
import SlateDomain
import SlateUI

enum SearchResultMapper {
    static func model(for hit: SearchHit, words: [String], type: NoteType?, now: Date) -> SearchResultRowModel {
        let summary = hit.summary
        var badges: [TagModel] = []
        if let ticket = summary.ticket {
            badges.append(TagModel(ticket, tint: .blue, systemImage: "ticket"))
        }
        if let status = summary.status {
            badges.append(TagModel(NoteStatusText.title(status), tint: NoteStatusText.tint(status)))
        }
        if summary.openTodos > 0 {
            badges.append(TagModel("\(summary.openTodos)", tint: .secondary, systemImage: "checklist", hint: CountText.count(summary.openTodos, "open checkbox", "open checkboxes")))
        }
        return SearchResultRowModel(
            id: summary.id,
            title: highlighted(summary.title, words: words),
            snippet: highlighted(hit.snippet, words: words),
            folder: summary.space?.rawValue,
            date: summary.updated.relativeDescription(to: now),
            typeIcon: summary.type == NoteType.defaultName ? nil : type?.icon,
            badges: badges
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
