import Foundation

package struct IndexedNote: Hashable, Sendable {
    package var summary: NoteSummary
    package var state: IndexedFileState

    package init(summary: NoteSummary, state: IndexedFileState) {
        self.summary = summary
        self.state = state
    }
}
