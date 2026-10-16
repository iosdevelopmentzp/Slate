import SlateDomain
import SlateMocks
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct NavigatorTests {
    @Test func restoresTheSpaceAndTheSelectedNote() {
        let store = InMemoryKeyValueStore()
        let first = Navigator(store: store)

        first.show(space: SpaceName(rawValue: "Tasks"))
        first.select(NoteID(rawValue: "c"))
        let second = Navigator(store: store)

        #expect(second.space == SpaceName(rawValue: "Tasks"))
        #expect(second.selectedNote == NoteID(rawValue: "c"))
    }

    @Test func clearingTheSpaceRemovesTheStoredValue() {
        let store = InMemoryKeyValueStore()
        let navigator = Navigator(store: store)
        navigator.show(space: SpaceName(rawValue: "Inbox"))

        navigator.show(space: nil)

        #expect(Navigator(store: store).space == nil)
    }
}
