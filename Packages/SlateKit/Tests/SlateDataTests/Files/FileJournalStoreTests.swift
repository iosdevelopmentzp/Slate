import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite struct FileJournalStoreTests {
    private let folder: TemporaryDirectory
    private let store: FileJournalStore

    init() throws {
        folder = try TemporaryDirectory()
        store = FileJournalStore(folder: folder.url.appendingPathComponent("journal"))
    }

    @Test func entriesRoundTripAndClear() async throws {
        let entry = JournalEntry(noteID: NoteID(rawValue: "a/b"), path: VaultPath(rawValue: "Inbox/A.md"), text: "typed", savedAt: Date(timeIntervalSince1970: 1_800_000_000))

        try await store.save(entry)
        #expect(try await store.entry(for: NoteID(rawValue: "a/b")) == entry)

        try await store.clear(NoteID(rawValue: "a/b"))
        #expect(try await store.entry(for: NoteID(rawValue: "a/b")) == nil)
    }

    @Test func missingEntryIsNil() async throws {
        #expect(try await store.entry(for: NoteID(rawValue: "none")) == nil)
        try await store.clear(NoteID(rawValue: "none"))
    }
}
