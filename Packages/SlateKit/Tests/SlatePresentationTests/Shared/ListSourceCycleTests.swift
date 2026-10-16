import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@Suite struct ListSourceCycleTests {
    private let spaces = [SpaceName(rawValue: "Notes"), SpaceName(rawValue: "Ideas")]

    @Test func cycleGoesThroughFoldersAndWraps() {
        #expect(ListSource.cycle(from: .all, spaces: spaces, by: 1) == .space(SpaceName(rawValue: "Notes")))
        #expect(ListSource.cycle(from: .all, spaces: spaces, by: -1) == .trash)
        #expect(ListSource.cycle(from: .trash, spaces: spaces, by: 1) == .all)
        #expect(ListSource.cycle(from: .space(SpaceName(rawValue: "Ideas")), spaces: spaces, by: 1) == .trash)
    }
}
