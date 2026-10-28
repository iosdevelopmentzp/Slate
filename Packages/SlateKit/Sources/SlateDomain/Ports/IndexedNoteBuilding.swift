import Foundation

package protocol IndexedNoteBuilding: Sendable {
    func build(_ document: NoteDocument) -> IndexedNote
    func text(ofFile path: VaultPath, data: Data) -> String?
}
