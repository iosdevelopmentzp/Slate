import Foundation

package struct DailyNote: Hashable, Sendable {
    package let document: NoteDocument
    package let wasCreated: Bool
    package let caret: Int

    package init(document: NoteDocument, wasCreated: Bool, caret: Int) {
        self.document = document
        self.wasCreated = wasCreated
        self.caret = caret
    }
}
