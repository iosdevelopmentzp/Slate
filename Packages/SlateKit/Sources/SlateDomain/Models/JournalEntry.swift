import Foundation

package struct JournalEntry: Hashable, Sendable, Codable {
    package let noteID: NoteID
    package var path: VaultPath
    package var text: String
    package var savedAt: Date

    package init(noteID: NoteID, path: VaultPath, text: String, savedAt: Date) {
        self.noteID = noteID
        self.path = path
        self.text = text
        self.savedAt = savedAt
    }
}
