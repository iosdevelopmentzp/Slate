import Foundation
import SlateDomain
import Testing
@testable import SlateData

@Suite struct MemorySearchIndexTests {
    private func note(_ path: String, id: String, updated: Double) -> IndexedNote {
        IndexedNote(
            summary: NoteSummary(id: NoteID(rawValue: id), path: VaultPath(rawValue: path), title: id, updated: Date(timeIntervalSince1970: updated), preview: ""),
            state: IndexedFileState(modified: .now, size: 1, hash: ContentHash(rawValue: id))
        )
    }

    @Test func summariesFilterBySpaceNewestFirst() async {
        let index = MemorySearchIndex()
        await index.upsert(note("Inbox/A.md", id: "a", updated: 1))
        await index.upsert(note("Inbox/B.md", id: "b", updated: 2))
        await index.upsert(note("Tasks/C.md", id: "c", updated: 3))

        #expect(await index.summaries(space: nil).map(\.id.rawValue) == ["c", "b", "a"])
        #expect(await index.summaries(space: SpaceName(rawValue: "Inbox")).map(\.id.rawValue) == ["b", "a"])
        #expect(await index.summary(id: NoteID(rawValue: "c"))?.path == VaultPath(rawValue: "Tasks/C.md"))
    }

    @Test func removeAndUpdateStateChangeTheEntry() async {
        let index = MemorySearchIndex()
        let path = VaultPath(rawValue: "Inbox/A.md")
        await index.upsert(note(path.rawValue, id: "a", updated: 1))
        let state = IndexedFileState(modified: Date(timeIntervalSince1970: 5), size: 9, hash: ContentHash(rawValue: "z"))

        await index.updateState(state, for: path)
        #expect(await index.fileStates()[path] == state)

        await index.remove(path: path)
        #expect(await index.fileStates().isEmpty)
    }
}
