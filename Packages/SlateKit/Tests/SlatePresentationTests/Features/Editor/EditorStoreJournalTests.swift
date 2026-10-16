import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct EditorStoreJournalTests {
    private let harness = StoreHarness()

    private var editor: EditorStore {
        harness.editor
    }

    private func open(body: String = "Body") async throws -> VaultPath {
        let path = harness.seed("Inbox/A.md", id: "a", title: "A", body: body)
        try await harness.index()
        harness.navigator.select(NoteID(rawValue: "a"))
        await editor.open(NoteID(rawValue: "a"))
        return path
    }

    @Test func unsavedTextIsKeptInTheJournal() async throws {
        _ = try await open()
        editor.text = "Body typed"

        await editor.writeJournal()

        #expect(harness.spies.journal.entries[NoteID(rawValue: "a")]?.text == "Body typed")
    }

    @Test func aNewerJournalIsOfferedAndRestored() async throws {
        let path = VaultPath(rawValue: "Inbox/A.md")
        harness.spies.journal.entries[NoteID(rawValue: "a")] = JournalEntry(noteID: NoteID(rawValue: "a"), path: path, text: "lost text", savedAt: Date.distantFuture)
        _ = try await open()

        #expect(editor.recovered?.text == "lost text")
        editor.restoreRecovered()

        #expect(editor.text == "lost text")
        #expect(editor.recovered == nil)
        try await waitUntil { harness.spies.files.text(at: path)?.hasSuffix("lost text") == true }
        try await waitUntil { harness.spies.journal.entries.isEmpty }
    }

    @Test func discardDropsTheJournal() async throws {
        harness.spies.journal.entries[NoteID(rawValue: "a")] = JournalEntry(noteID: NoteID(rawValue: "a"), path: VaultPath(rawValue: "Inbox/A.md"), text: "lost", savedAt: Date.distantFuture)
        _ = try await open()

        editor.discardRecovered()

        #expect(editor.recovered == nil)
        try await waitUntil { harness.spies.journal.entries.isEmpty }
    }

    @Test func anOlderJournalIsDropped() async throws {
        harness.spies.journal.entries[NoteID(rawValue: "a")] = JournalEntry(noteID: NoteID(rawValue: "a"), path: VaultPath(rawValue: "Inbox/A.md"), text: "old", savedAt: Date.distantPast)
        _ = try await open()

        #expect(editor.recovered == nil)
        try await waitUntil { harness.spies.journal.entries.isEmpty }
    }

    @Test func openBothKeepsMyTextAsACopy() async throws {
        let path = try await open()
        editor.text = "mine"
        harness.spies.files.seed(path, NoteText.make(id: "a", title: "A", body: "theirs"))

        await editor.openBoth()

        #expect(editor.text == "theirs")
        let copy = try #require(harness.spies.index.indexed.values.first { $0.title.hasPrefix("A (conflict ") })
        #expect(try await harness.document(at: copy.path).body == "mine")
    }
}
