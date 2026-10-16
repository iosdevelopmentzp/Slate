import Foundation
import GRDB
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite struct GRDBSearchIndexTests {
    private let index: GRDBSearchIndex
    private let builder = IndexedNoteBuilder()

    init() throws {
        index = try GRDBSearchIndex(writer: DatabaseQueue())
    }

    private func note(_ path: String, id: String, title: String? = nil, type: String? = nil, ticket: String? = nil, pinned: Bool = false, tags: [String]? = nil, status: String? = nil, updated: TimeInterval = 1_000, body: String) -> IndexedNote {
        let vaultPath = VaultPath(rawValue: path)
        let header = NoteHeader(id: NoteID(rawValue: id), title: title ?? vaultPath.stem, type: type, updated: Date(timeIntervalSince1970: updated), tags: tags, pinned: pinned, ticket: ticket, status: status)
        let meta = FileMeta(path: vaultPath, created: Date(timeIntervalSince1970: 1), modified: Date(timeIntervalSince1970: updated), size: body.utf8.count)
        return builder.build(NoteDocument(path: vaultPath, header: header, body: body, hash: ContentHash(rawValue: id), meta: meta))
    }

    private func search(_ text: String, limit: Int = 20) async throws -> [String] {
        try await index.search(SearchQueryParser.parse(text, now: Date(timeIntervalSince1970: 2_000), timeZone: .gmt), limit: limit).map(\.summary.title)
    }

    @Test func upsertThenSummaries() async throws {
        try await index.upsert(note("Tasks/A.md", id: "a", ticket: "ABC-1", tags: ["ios"], body: "Hello #audio\n- [ ] one\n- [x] two"))

        let summary = try #require(try await index.summaries(space: nil).first)
        #expect(summary.title == "A")
        #expect(summary.ticket == "ABC-1")
        #expect(summary.tags == ["audio", "ios"])
        #expect(summary.openTodos == 1)
        #expect(try await index.summaries(space: SpaceName(rawValue: "Notes")).isEmpty)
        #expect(try await index.summary(id: NoteID(rawValue: "a"))?.path == VaultPath(rawValue: "Tasks/A.md"))
    }

    @Test func upsertReplacesTheOldRow() async throws {
        try await index.upsert(note("Notes/A.md", id: "a", body: "first words"))
        try await index.upsert(note("Notes/A.md", id: "a", body: "second words"))

        #expect(try await search("first").isEmpty)
        #expect(try await search("second") == ["A"])
        #expect(try await index.summaries(space: nil).count == 1)
    }

    @Test func aDuplicateIDGetsAPathID() async throws {
        try await index.upsert(note("Notes/A.md", id: "same", body: "a"))
        try await index.upsert(note("Notes/B.md", id: "same", body: "b"))

        let ids = Set(try await index.summaries(space: nil).map(\.id.rawValue))
        #expect(ids == ["same", "path:Notes/B.md"])
    }

    @Test func removeDeletesEverything() async throws {
        try await index.upsert(note("Notes/A.md", id: "a", tags: ["x"], body: "words [[B]]"))

        try await index.remove(path: VaultPath(rawValue: "Notes/A.md"))

        #expect(try await index.summaries(space: nil).isEmpty)
        #expect(try await search("words").isEmpty)
        #expect(try await index.tags().isEmpty)
        #expect(try await index.notesLinking(to: "B").isEmpty)
    }

    @Test func fileStatesRoundTrip() async throws {
        try await index.upsert(note("Notes/A.md", id: "a", updated: 1_234.5, body: "x"))

        let state = try #require(try await index.fileStates()[VaultPath(rawValue: "Notes/A.md")])
        #expect(state.matches(FileMeta(path: VaultPath(rawValue: "Notes/A.md"), created: .distantPast, modified: Date(timeIntervalSince1970: 1_234.5), size: 1)))

        try await index.updateState(IndexedFileState(modified: Date(timeIntervalSince1970: 9), size: 7, hash: ContentHash(rawValue: "h")), for: VaultPath(rawValue: "Notes/A.md"))
        #expect(try await index.fileStates()[VaultPath(rawValue: "Notes/A.md")]?.size == 7)
    }

    @Test func searchFindsWordsByPrefixAndRanksTitlesFirst() async throws {
        try await index.upsert(note("Notes/A.md", id: "a", title: "Engine notes", body: "the retain cycle is in the audio engine"))
        try await index.upsert(note("Notes/B.md", id: "b", title: "Retain cycle", body: "fixed in the engine delegate"))
        try await index.upsert(note("Notes/C.md", id: "c", title: "Other", body: "nothing here"))

        #expect(try await search("retain engine") == ["Retain cycle", "Engine notes"])
        #expect(try await search("reta") == ["Retain cycle", "Engine notes"])
    }

    @Test func snippetShowsTheMatchingText() async throws {
        try await index.upsert(note("Notes/A.md", id: "a", body: String(repeating: "filler ", count: 40) + "the retain cycle " + String(repeating: "more ", count: 40)))

        let hit = try #require(try await index.search(SearchQuery(terms: ["retain"]), limit: 5).first)
        #expect(hit.snippet.contains("retain"))
        #expect(hit.snippet.contains("…"))
    }

    @Test func phrasesAndExclusions() async throws {
        try await index.upsert(note("Notes/A.md", id: "a", body: "audio engine delegate"))
        try await index.upsert(note("Notes/B.md", id: "b", body: "engine audio draft"))

        #expect(try await search(#""audio engine""#) == ["A"])
        #expect(try await search("audio -draft") == ["A"])
        #expect(try await search("-draft") == ["A"])
    }

    @Test func filters() async throws {
        try await index.upsert(note("Tasks/T1.md", id: "t1", type: "task", ticket: "ABC-2324", tags: ["audio/engine"], status: "active", body: "- [ ] fix\n```swift\nx\n```"))
        try await index.upsert(note("Tasks/T2.md", id: "t2", type: "task", status: "done", body: "![](../_attachments/a.png)"))
        try await index.upsert(note("Notes/N.md", id: "n", pinned: true, updated: 1_500, body: "plain https://example.com"))

        #expect(try await search("type:task status:active") == ["T1"])
        #expect(try await search("tag:audio") == ["T1"])
        #expect(try await search("ticket:abc-2324") == ["T1"])
        #expect(try await search("is:todo") == ["T1"])
        #expect(try await search("has:code") == ["T1"])
        #expect(try await search("has:image") == ["T2"])
        #expect(try await search("has:link") == ["N"])
        #expect(try await search("is:pinned") == ["N"])
        #expect(try await search("space:tasks -status:done") == ["T1"])
        #expect(try await search("after:1970-01-01").first == "N")
        #expect(try await search("-has:tag").count == 2)
    }

    @Test func hostileInputNeverThrows() async throws {
        try await index.upsert(note("Notes/A.md", id: "a", body: "x"))

        for text in [#"""#, #"a "b"#, "'", "(", ")", ":", "-", "a:b", "AND OR NOT", "*", "NEAR(", #"\"#, "^x"] {
            _ = try await search(text)
        }
    }

    @Test func lookupsByStemTicketAndLinks() async throws {
        try await index.upsert(note("Notes/Plan.md", id: "p", ticket: "ABC-9", body: "x"))
        try await index.upsert(note("Notes/Ref.md", id: "r", body: "see [[plan]] and [[Notes/Plan#x]]"))

        #expect(try await index.notes(named: "PLAN").map(\.id.rawValue) == ["p"])
        #expect(try await index.notes(withTicket: "abc-9").map(\.id.rawValue) == ["p"])
        #expect(try await index.notesLinking(to: "Plan").map(\.id.rawValue) == ["r"])
    }

    @Test func tagsAndTodos() async throws {
        try await index.upsert(note("Notes/A.md", id: "a", tags: ["b"], body: "#a\n- [ ] one\n- [x] two"))
        try await index.upsert(note("Notes/B.md", id: "b", body: "#a"))

        #expect(try await index.tags() == [TagCount(tag: "a", count: 2), TagCount(tag: "b", count: 1)])
        #expect(try await index.todos(isDone: false) == [TodoItem(noteID: NoteID(rawValue: "a"), line: 1, text: "one", isDone: false)])
    }

    @Test func resetEmptiesTheIndex() async throws {
        try await index.upsert(note("Notes/A.md", id: "a", body: "x"))

        try await index.reset()

        #expect(try await index.summaries(space: nil).isEmpty)
    }

    @Test func openRebuildsAFileFromAnotherVault() async throws {
        let folder = try TemporaryDirectory()
        let url = folder.url.appendingPathComponent("support/index.sqlite")
        let first = try GRDBSearchIndex.open(at: url, vaultPath: "/a")
        try await first.upsert(note("Notes/A.md", id: "a", body: "x"))

        let same = try GRDBSearchIndex.open(at: url, vaultPath: "/a")
        #expect(try await same.summaries(space: nil).count == 1)
        let other = try GRDBSearchIndex.open(at: url, vaultPath: "/b")
        #expect(try await other.summaries(space: nil).isEmpty)
    }
}
