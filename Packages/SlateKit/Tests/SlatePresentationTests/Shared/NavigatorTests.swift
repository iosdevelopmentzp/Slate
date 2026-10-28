import SlateDomain
import SlateMocks
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct NavigatorTests {
    @Test func restoresTheSourceAndTheSelectedNote() {
        let store = InMemoryKeyValueStore()
        let first = Navigator(store: store)

        first.show(.space(SpaceName(rawValue: "Ideas")))
        first.select(NoteID(rawValue: "c"))
        let second = Navigator(store: store)

        #expect(second.source == .space(SpaceName(rawValue: "Ideas")))
        #expect(second.selectedNote == NoteID(rawValue: "c"))
    }

    @Test func selectingAFileClearsTheNoteAndTheOtherWayRound() {
        let navigator = Navigator(store: InMemoryKeyValueStore())
        let file = VaultPath(rawValue: "Work/App.swift")
        navigator.select(NoteID(rawValue: "c"))

        navigator.select(file: file)
        #expect(navigator.selectedNote == nil)
        #expect(navigator.selectedFile == file)

        navigator.select(NoteID(rawValue: "d"))
        #expect(navigator.selectedFile == nil)
        #expect(navigator.selectedNote == NoteID(rawValue: "d"))
    }

    @Test func theSelectedFileIsRestored() {
        let store = InMemoryKeyValueStore()
        Navigator(store: store).select(file: VaultPath(rawValue: "Work/App.swift"))

        #expect(Navigator(store: store).selectedFile == VaultPath(rawValue: "Work/App.swift"))
    }

    @Test func trashAndAllAreRestoredToo() {
        let store = InMemoryKeyValueStore()
        Navigator(store: store).show(.trash)

        #expect(Navigator(store: store).source == .trash)

        Navigator(store: store).show(.all)
        #expect(Navigator(store: store).source == .all)
    }
}
