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

    func upsert(contentsOf notes: [IndexedNote]) {
        for note in notes {
            self.notes[note.summary.path] = note
        }
    }

    func search(_ query: SearchQuery, limit: Int) -> [SearchHit] {
        SearchMatchPolicy.hits(in: Array(notes.values), query: query, limit: limit)
    }

    func notes(named stem: String) -> [NoteSummary] {
        notes.values.map(\.summary).filter { StemPolicy.isSame($0.stem, stem) }
    }

    func notes(withTicket ticket: String) -> [NoteSummary] {
        notes.values.map(\.summary).filter { $0.ticket == ticket }
    }

    func notesLinking(to stem: String) -> [NoteSummary] {
        notes.values.filter { $0.links.contains { WikilinkPolicy.parse($0.target).stem == stem } }.map(\.summary)
    }

    func tags() -> [TagCount] {
        let all = notes.values.flatMap(\.summary.tags)
        return Dictionary(grouping: all, by: { $0 }).map { TagCount(tag: $0.key, count: $0.value.count) }.sorted { $0.tag < $1.tag }
    }

    func todos(isDone: Bool) -> [TodoItem] {
        notes.values.flatMap(\.todos).filter { $0.isDone == isDone }
    }

    func reset() {
        notes.removeAll()
    }
}
