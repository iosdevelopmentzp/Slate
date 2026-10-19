import Foundation
import Testing
@testable import SlateEditor

@MainActor
@Suite struct MultiCaretTests {
    @Test func anEditMovesTheCaretsAfterIt() {
        let positions = MultiCaret.shifted([2, 8, 14], editing: 1, range: NSRange(location: 8, length: 0), insertedLength: 3)

        #expect(positions == [2, 11, 17])
    }

    @Test func aDeletionMovesTheCaretsAfterItBack() {
        let positions = MultiCaret.shifted([2, 8, 14], editing: 2, range: NSRange(location: 13, length: 1), insertedLength: 0)

        #expect(positions == [2, 8, 13])
    }

    @Test func caretsInOnePlaceBecomeOne() {
        let merged = MultiCaret.merged([4, 9, 4, 30], primary: 2, limit: 20)

        #expect(merged.primary == 4)
        #expect(merged.extras == [9, 20])
    }
}
