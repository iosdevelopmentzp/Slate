import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct FindSegmentsTests {
    private let note = "Intro\n\n| a | b |\n|---|---|\n| 1 | milk |\n\nAfter\n"

    @Test func cellsJoinTheTextBetweenTheParagraphs() {
        let harness = EditorHarness(markdown: note)

        let segments = FindSegments.make(harness.controller.storage)

        #expect(segments.items.map(\.string) == ["Intro\n", "a", "b", "1", "milk", "\nAfter"])
        #expect(segments.length == 19)
        #expect(segments.items[4].place == .cell(table: 6, index: TableCellIndex(row: 1, column: 1)))
        #expect(segments.items[4].group == NSRange(location: 6, length: 7))
    }

    @Test func storageLocationsMapAroundTheTable() {
        let harness = EditorHarness(markdown: note)
        let segments = FindSegments.make(harness.controller.storage)

        #expect(segments.virtualLocation(ofStorage: 2) == 2)
        #expect(segments.virtualLocation(ofStorage: 6) == 6)
        #expect(segments.virtualLocation(ofStorage: 8) == 14)
    }

    @Test func emptyCellsAreLeftOut() {
        let harness = EditorHarness(markdown: "| a | |\n|---|---|\n| | b |\n")

        let segments = FindSegments.make(harness.controller.storage)

        #expect(segments.items.map(\.string) == ["a", "b"])
    }

    @Test func aRangeMapsIntoItsSegment() throws {
        let harness = EditorHarness(markdown: note)
        let segments = FindSegments.make(harness.controller.storage)

        let (item, local) = try #require(segments.local(NSRange(location: 10, length: 3)))

        #expect(item.string == "milk")
        #expect(local == NSRange(location: 1, length: 3))
    }
}
