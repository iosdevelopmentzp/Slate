import Foundation
import Testing
@testable import SlateEditor

@Suite struct TableModelTests {
    private func sample() -> TableModel {
        var model = TableModel.empty(columns: 2, rows: 2)
        for row in 0..<3 {
            for column in 0..<2 {
                model.setCell(TableCellIndex(row: row, column: column), markdown: "\(row)\(column)")
            }
        }
        return model
    }

    private func grid(_ model: TableModel) -> [[String]] {
        model.allRows.map { $0.map(\.markdown) }
    }

    @Test func emptyIsAHeaderAndOneRow() {
        let model = TableModel.empty()

        #expect(model.columnCount == 2)
        #expect(model.rowCount == 2)
        #expect(model.filledCellCount == 0)
    }

    @Test func rowsAreAddedBelowTheHeaderOnly() {
        var model = sample()

        model.insertRow(at: 0)
        model.insertRow(at: 99)

        #expect(grid(model) == [["00", "01"], ["", ""], ["10", "11"], ["20", "21"], ["", ""]])
    }

    @Test func theHeaderRowCannotBeDeleted() {
        var model = sample()

        model.deleteRow(0)
        model.deleteRow(1)

        #expect(grid(model) == [["00", "01"], ["20", "21"]])
    }

    @Test func columnsAreAddedAndDeletedInEveryRow() {
        var model = sample()

        model.insertColumn(at: 1)
        #expect(grid(model) == [["00", "", "01"], ["10", "", "11"], ["20", "", "21"]])
        #expect(model.columns.count == 3)

        model.deleteColumn(0)
        #expect(grid(model) == [["", "01"], ["", "11"], ["", "21"]])
    }

    @Test func theLastColumnStays() {
        var model = TableModel.empty(columns: 1, rows: 1)

        model.deleteColumn(0)

        #expect(model.columnCount == 1)
    }

    @Test func alignmentIsPerColumn() {
        var model = sample()

        model.setAlignment(.center, column: 1)
        model.setAlignment(.right, column: 5)

        #expect(model.columns.map(\.alignment) == [.none, .center])
    }

    @Test func cellsOutsideTheTableAreIgnored() {
        var model = sample()

        model.setCell(TableCellIndex(row: 7, column: 0), markdown: "x")

        #expect(model == sample())
        #expect(model.cell(TableCellIndex(row: 7, column: 0)) == TableCell())
        #expect(model.filledCellCount == 6)
    }

    @Test func aBlockKeepsItsSourceUntilTheModelChanges() {
        let source = "|a|b|\n|-|-|\n|1|2|"
        var block = TableBlock(model: TableMarkdown.parse(source) ?? .empty(), source: source)

        #expect(block.markdown == source)
        block.model.setCell(TableCellIndex(row: 1, column: 0), markdown: "9")
        #expect(block.markdown == "| a | b |\n| --- | --- |\n| 9 | 2 |")
    }
}
