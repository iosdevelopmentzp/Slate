import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct PaletteStoreTests {
    private let harness = StoreHarness()

    private var palette: PaletteStore {
        harness.palette
    }

    @Test func commandsMatchAllWords() {
        #expect(PaletteStore.matches("Copy for Slack", query: "slack cop"))
        #expect(PaletteStore.matches("Copy for Slack", query: "paste") == false)
        #expect(PaletteStore.matches("Anything", query: ""))
    }

    @Test func emptyQueryShowsRecentNotes() async throws {
        harness.seed("Notes/A.md", id: "a", title: "A")
        harness.seed("Notes/B.md", id: "b", title: "B")
        try await harness.index()
        await harness.noteList.refresh()
        harness.navigator.select(NoteID(rawValue: "a"))
        harness.navigator.select(NoteID(rawValue: "b"))

        palette.open()

        #expect(palette.recentHits.map(\.id.rawValue) == ["b", "a"])
    }

    @Test func typingFindsNotesThenCommands() async throws {
        harness.seed("Notes/Retain cycle.md", id: "a", title: "Retain cycle", body: "audio")
        try await harness.index()
        await harness.noteList.refresh()
        let commands = [PaletteCommand("Retain search", icon: "x") {}, PaletteCommand("Other", icon: "x") {}]

        palette.open()
        palette.query = "retain"
        await palette.waitForResults()

        let items = palette.items(commands: commands)
        #expect(items.map(\.id) == ["note:a", "command:Retain search"])
    }

    @Test func selectionWrapsAround() {
        palette.move(-1, count: 3)
        #expect(palette.selection == 2)
        palette.move(1, count: 3)
        #expect(palette.selection == 0)
    }

    @Test func recentNotesAreRemembered() {
        harness.navigator.select(NoteID(rawValue: "x"))
        harness.navigator.select(NoteID(rawValue: "y"))
        harness.navigator.select(NoteID(rawValue: "x"))

        #expect(harness.navigator.recent.map(\.rawValue) == ["x", "y"])
        #expect(Navigator(store: harness.keyValues).recent.map(\.rawValue) == ["x", "y"])
    }
}
