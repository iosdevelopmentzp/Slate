import Foundation

package struct SearchHit: Identifiable, Hashable, Sendable {
    package var summary: NoteSummary
    package var excerpt: String
    package var rank: Double

    package var id: NoteID {
        summary.id
    }

    package init(summary: NoteSummary, excerpt: String, rank: Double) {
        self.summary = summary
        self.excerpt = excerpt
        self.rank = rank
    }
}
