import Foundation
import SlateDomain

package struct SpyIndexedNoteBuilder: IndexedNoteBuilding {
    package init() {}

    package func build(_ document: NoteDocument) -> IndexedNote {
        IndexFactsPolicy.note(for: document)
    }
}
