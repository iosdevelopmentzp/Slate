import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct TableModelRangeTests {
    private var model: TableModel {
        TableMarkdown.parse("| a | b | c |\n|---|---|---|\n| 1 | **2** | 3 |\n| 4 | 5 | 6 |") ?? .empty()
    }

    private func range(_ anchor: (Int, Int), _ head: (Int, Int)) -> TableCellRange {
        TableCellRange(anchor: TableCellIndex(row: anchor.0, column: anchor.1), head: TableCellIndex(row: head.0, column: head.1))
    }

    @Test func aRangeCoversTheRectangleInAnyDirection() {
        let selection = range((2, 2), (1, 0))

        #expect(selection.rows == 1...2)
        #expect(selection.columns == 0...2)
        #expect(selection.topLeft == TableCellIndex(row: 1, column: 0))
        #expect(selection.indexes.count == 6)
    }

    @Test func sliceKeepsTheSelectedCells() {
        let slice = model.slice(range((1, 1), (2, 2)))

        #expect(TableMarkdown.render(slice) == "| **2** | 3 |\n| --- | --- |\n| 5 | 6 |")
    }

    @Test func clearEmptiesOnlyTheRange() {
        var changed = model
        changed.clear(range((1, 0), (1, 1)))

        #expect(changed.allRows.map { $0.map(\.markdown) } == [["a", "b", "c"], ["", "", "3"], ["4", "5", "6"]])
    }

    @Test func pasteGrowsTheTableWhenNeeded() {
        var changed = model
        let source = TableMarkdown.parse("| x | y |\n|---|---|\n| z | w |") ?? .empty()

        changed.paste(source, at: TableCellIndex(row: 2, column: 2))

        #expect(changed.rowCount == 4)
        #expect(changed.columnCount == 4)
        #expect(changed.cell(TableCellIndex(row: 3, column: 3)).markdown == "w")
    }

    @Test func toggleBoldAddsItUnlessEveryCellHasIt() {
        var changed = model
        changed.toggle(.bold, in: range((1, 0), (1, 1)))
        #expect(changed.allRows[1].map(\.markdown) == ["**1**", "**2**", "3"])

        changed.toggle(.bold, in: range((1, 0), (1, 1)))
        #expect(changed.allRows[1].map(\.markdown) == ["1", "2", "3"])
    }

    @Test func deletingRowsKeepsTheHeaderAndOneRow() {
        var changed = model
        changed.deleteRows(0...2)

        #expect(changed.header.map(\.markdown) == ["a", "b", "c"])
        #expect(changed.rows.count == 1)
    }

    @Test func deletingColumnsKeepsOne() {
        var changed = model
        changed.deleteColumns(0...2)

        #expect(changed.columnCount == 1)
    }
}
