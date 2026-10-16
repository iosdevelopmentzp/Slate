import Foundation

package struct TodoItem: Hashable, Sendable {
    package var noteID: NoteID
    package var line: Int
    package var text: String
    package var isDone: Bool

    package init(noteID: NoteID, line: Int, text: String, isDone: Bool) {
        self.noteID = noteID
        self.line = line
        self.text = text
        self.isDone = isDone
    }
}
