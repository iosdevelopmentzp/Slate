import Foundation

package struct LoggedProgress: Hashable, Sendable {
    package let document: NoteDocument
    package let entry: String

    package init(document: NoteDocument, entry: String) {
        self.document = document
        self.entry = entry
    }
}
