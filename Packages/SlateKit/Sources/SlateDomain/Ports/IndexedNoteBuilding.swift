import Foundation

package protocol IndexedNoteBuilding: Sendable {
    func build(_ document: NoteDocument) -> IndexedNote
}
