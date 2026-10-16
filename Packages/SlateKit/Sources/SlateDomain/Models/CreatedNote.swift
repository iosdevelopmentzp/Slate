import Foundation

package struct CreatedNote: Hashable, Sendable {
    package let document: NoteDocument
    package let caret: Int

    package init(document: NoteDocument, caret: Int) {
        self.document = document
        self.caret = caret
    }
}
