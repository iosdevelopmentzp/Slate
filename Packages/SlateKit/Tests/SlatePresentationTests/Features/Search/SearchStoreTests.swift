import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct SearchStoreTests {
    private let harness = StoreHarness()

    private var search: SearchStore {
        harness.search
    }

    private func seed() async throws {
        harness.seed("Notes/Retain cycle.md", id: "a", title: "Retain cycle", body: "in the audio engine #audio")
        harness.seed("Tasks/Engine.md", id: "b", title: "Engine", body: "the retain cycle again\n- [ ] fix")
        harness.seed("Notes/Other.md", id: "c", title: "Other", body: "nothing")
        try await harness.index()
        await harness.noteList.refresh()
    }

    @Test func titleMatchesShowAtOnceThenTheIndexAnswers() async throws {
        try await seed()

        search.query = "retain"

        #expect(search.results.map(\.id.rawValue) == ["a"])
        await search.waitForResults()
        #expect(search.results.map(\.id.rawValue) == ["a", "b"])
        #expect(search.isSearching == false)
    }

    @Test func searchStaysInTheCurrentFolder() async throws {
        try await seed()
        harness.navigator.show(.space(SpaceName(rawValue: "Tasks")))

        search.query = "retain"
        await search.waitForResults()

        #expect(search.results.map(\.id.rawValue) == ["b"])
        #expect(search.scopeName == "Tasks")
        search.searchAllNotes()
        await search.waitForResults()
        #expect(search.results.count == 2)
    }

    @Test func filtersReachTheIndex() async throws {
        try await seed()

        search.query = "is:todo"
        await search.waitForResults()

        #expect(search.results.map(\.id.rawValue) == ["b"])
        #expect(harness.spies.index.calls.contains(.search(SearchQuery(filters: [.state(.todo)]))))
    }

    @Test func clearingEmptiesTheResults() async throws {
        try await seed()
        search.query = "retain"
        await search.waitForResults()

        search.clear()

        #expect(search.results.isEmpty)
        #expect(search.isActive == false)
    }

    @Test func openingAResultSelectsItAndAsksForTheMatch() async throws {
        try await seed()
        search.query = "engine"
        await search.waitForResults()
        harness.clearPosted()

        search.openFirst()

        let first = try #require(search.results.first)
        #expect(harness.navigator.selectedNote == first.id)
        #expect(harness.posted == [.searchOpened(first.id, words: ["engine"])])
    }

    @Test func tagsComeFromTheIndex() async throws {
        try await seed()

        await search.refreshTags()

        #expect(search.tags == [TagCount(tag: "audio", count: 1)])
        search.showTag("audio")
        #expect(search.query == "tag:audio")
    }

    @Test func openedSearchMovesTheCaretToTheMatch() async throws {
        try await seed()
        harness.navigator.select(NoteID(rawValue: "b"))
        await harness.editor.open(NoteID(rawValue: "b"))

        harness.events.post(.searchOpened(NoteID(rawValue: "b"), words: ["cycle"]))

        #expect(harness.editor.bodyFocus?.caret == 11)
    }
}
