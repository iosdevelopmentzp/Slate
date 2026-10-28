import Foundation
import SlateDomain

package struct SpyIndexedNoteBuilder: IndexedNoteBuilding {
    package init() {}

    package func build(_ document: NoteDocument) -> IndexedNote {
        IndexFactsPolicy.note(for: document)
    }

    package func text(ofFile path: VaultPath, data: Data) -> String? {
        FileKindPolicy.mayBeText(path, size: data.count) ? FileKindPolicy.text(from: data) : nil
    }
}
