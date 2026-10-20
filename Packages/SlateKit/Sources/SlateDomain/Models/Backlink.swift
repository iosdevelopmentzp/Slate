import Foundation

package struct Backlink: Hashable, Sendable, Identifiable {
    package let note: NoteSummary
    package let context: String

    package init(note: NoteSummary, context: String) {
        self.note = note
        self.context = context
    }

    package var id: NoteID {
        note.id
    }
}
