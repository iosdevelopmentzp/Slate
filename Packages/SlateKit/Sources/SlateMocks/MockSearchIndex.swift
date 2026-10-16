import Foundation
import SlateDomain

package final class MockSearchIndex: SearchIndex {
    private let notes: [NoteSummary]

    package init(notes: [NoteSummary] = MockVault.notes) {
        self.notes = notes
    }

    package func summaries(space: SpaceName?) async throws -> [NoteSummary] {
        guard let space else { return notes }
        return notes.filter { $0.space == space }
    }
}
