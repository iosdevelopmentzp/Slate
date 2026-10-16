import Foundation

package enum SearchMatchPolicy {
    package static func hits(in notes: [IndexedNote], query: SearchQuery, limit: Int) -> [SearchHit] {
        let hits = notes.filter { matches($0, query) }.map { note in
            SearchHit(summary: note.summary, snippet: snippet(of: note.body, words: query.words), rank: 0)
        }
        return Array(sorted(hits, words: query.words).prefix(limit))
    }

    package static func matches(_ note: IndexedNote, _ query: SearchQuery) -> Bool {
        let haystack = ([note.summary.title, note.body, note.summary.ticket ?? ""] + note.summary.tags).joined(separator: "\n")
        for term in query.terms where SearchHighlightPolicy.ranges(of: [term], in: haystack).isEmpty {
            return false
        }
        for phrase in query.phrases where haystack.range(of: phrase, options: [.caseInsensitive, .diacriticInsensitive]) == nil {
            return false
        }
        for term in query.excludedTerms where SearchHighlightPolicy.ranges(of: [term], in: haystack).isEmpty == false {
            return false
        }
        return query.filters.allSatisfy { matches(note, $0) } && query.excludedFilters.allSatisfy { matches(note, $0) == false }
    }

    package static func matches(_ note: IndexedNote, _ filter: SearchFilter) -> Bool {
        let summary = note.summary
        switch filter {
        case .tag(let tag):
            return summary.tags.contains { $0 == tag || $0.hasPrefix(tag + "/") }
        case .space(let space):
            return summary.space.map { StemPolicy.isSame($0.rawValue, space) } ?? false
        case .type(let type):
            return summary.type == type
        case .ticket(let ticket):
            return summary.ticket.map { StemPolicy.isSame($0, ticket) } ?? false
        case .status(let status):
            return summary.status?.rawValue == status
        case .state(.todo):
            return summary.openTodos > 0
        case .state(.pinned):
            return summary.pinned
        case .state(.trashed), .state(.conflict):
            return false
        case .has(.image):
            return note.hasImage
        case .has(.code):
            return note.hasCode
        case .has(.link):
            return note.hasLink
        case .has(.tag):
            return summary.tags.isEmpty == false
        case .before(let date):
            return summary.updated < date
        case .after(let date):
            return summary.updated >= date
        }
    }

    package static func snippet(of body: String, words: [String], radius: Int = 60) -> String {
        let flat = body.replacingOccurrences(of: "\n", with: " ")
        guard let first = SearchHighlightPolicy.ranges(of: words, in: flat).first else {
            return String(flat.prefix(radius * 2)).trimmingCharacters(in: .whitespaces)
        }
        let ns = flat as NSString
        let start = max(0, first.location - radius / 2)
        let end = min(ns.length, first.upperBound + radius)
        let piece = ns.substring(with: NSRange(location: start, length: end - start)).trimmingCharacters(in: .whitespaces)
        return (start > 0 ? "…" : "") + piece + (end < ns.length ? "…" : "")
    }

    package static func sorted(_ hits: [SearchHit], words: [String]) -> [SearchHit] {
        hits.sorted { lhs, rhs in
            let left = SearchHighlightPolicy.titleScore(lhs.summary.title, words: words)
            let right = SearchHighlightPolicy.titleScore(rhs.summary.title, words: words)
            if left != right { return left > right }
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            if lhs.summary.pinned != rhs.summary.pinned { return lhs.summary.pinned }
            return lhs.summary.updated > rhs.summary.updated
        }
    }
}
