import Foundation
import SlateDomain

struct MockIndexedNoteBuilder: IndexedNoteBuilding {
    func build(_ document: NoteDocument) -> IndexedNote {
        IndexFactsPolicy.note(for: document)
    }
}
