import Foundation
import SlateDomain

struct MockIndexedNoteBuilder: IndexedNoteBuilding {
    func build(_ document: NoteDocument) -> IndexedNote {
        IndexFactsPolicy.note(for: document)
    }

    func text(ofFile path: VaultPath, data: Data) -> String? {
        FileKindPolicy.mayBeText(path, size: data.count) ? FileKindPolicy.text(from: data) : nil
    }
}
