import Foundation
import SlateDomain

actor MockSearchIndex: SearchIndex {
    private var notes: [VaultPath: IndexedNote]

    init(documents: [NoteDocument] = MockVault.documents) {
        let builder = MockIndexedNoteBuilder()
        notes = Dictionary(uniqueKeysWithValues: documents.map { ($0.path, builder.build($0)) })
    }

    func summaries(space: SpaceName?) -> [NoteSummary] {
        notes.values.map(\.summary).filter { space == nil || $0.space == space }
    }

    func summary(id: NoteID) -> NoteSummary? {
        notes.values.first { $0.summary.id == id }?.summary
    }

    func fileStates() -> [VaultPath: IndexedFileState] {
        notes.mapValues(\.state)
    }

    func upsert(_ note: IndexedNote) {
        notes[note.summary.path] = note
    }

    func updateState(_ state: IndexedFileState, for path: VaultPath) {
        notes[path]?.state = state
    }

    func remove(path: VaultPath) {
        notes[path] = nil
    }
}
