import SlateDomain
import SlateMocks
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct NavigatorTests {
    @Test func restoresTheSourceAndTheSelectedNote() {
        let store = InMemoryKeyValueStore()
        let first = Navigator(store: store)

        first.show(.space(SpaceName(rawValue: "Tasks")))
        first.select(NoteID(rawValue: "c"))
        let second = Navigator(store: store)

        #expect(second.source == .space(SpaceName(rawValue: "Tasks")))
        #expect(second.selectedNote == NoteID(rawValue: "c"))
    }

    @Test func trashAndAllAreRestoredToo() {
        let store = InMemoryKeyValueStore()
        Navigator(store: store).show(.trash)

        #expect(Navigator(store: store).source == .trash)

        Navigator(store: store).show(.all)
        #expect(Navigator(store: store).source == .all)
    }
}
