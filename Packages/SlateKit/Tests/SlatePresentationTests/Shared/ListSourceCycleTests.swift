import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@Suite struct ListSourceCycleTests {
    private let spaces = [SpaceName(rawValue: "Inbox"), SpaceName(rawValue: "Tasks")]

    @Test func cycleGoesThroughFoldersAndWraps() {
        #expect(ListSource.cycle(from: .all, spaces: spaces, by: 1) == .space(SpaceName(rawValue: "Inbox")))
        #expect(ListSource.cycle(from: .all, spaces: spaces, by: -1) == .trash)
        #expect(ListSource.cycle(from: .trash, spaces: spaces, by: 1) == .all)
        #expect(ListSource.cycle(from: .space(SpaceName(rawValue: "Tasks")), spaces: spaces, by: 1) == .todos)
    }

    @Test func todosIsStored() {
        #expect(ListSource(storedValue: ListSource.todos.storedValue) == .todos)
    }
}
