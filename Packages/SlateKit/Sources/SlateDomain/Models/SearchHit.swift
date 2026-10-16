import Foundation

package struct SearchHit: Identifiable, Hashable, Sendable {
    package var summary: NoteSummary
    package var snippet: String
    package var rank: Double

    package var id: NoteID {
        summary.id
    }

    package init(summary: NoteSummary, snippet: String, rank: Double) {
        self.summary = summary
        self.snippet = snippet
        self.rank = rank
    }
}
