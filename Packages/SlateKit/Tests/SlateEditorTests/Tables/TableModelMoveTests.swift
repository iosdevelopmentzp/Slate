import Foundation
import Testing
@testable import SlateEditor

@Suite struct TableModelMoveTests {
    private func sample() -> TableModel {
        var model = TableModel.empty(columns: 3, rows: 3)
        model.columns[0].alignment = .right
        for row in 0..<4 {
            for column in 0..<3 {
                model.setCell(TableCellIndex(row: row, column: column), markdown: "\(row)\(column)")
            }
        }
        return model
    }

    private func grid(_ model: TableModel) -> [[String]] {
        model.allRows.map { $0.map(\.markdown) }
    }

    @Test func aRowMovesUpAndDownUnderTheHeader() {
        var model = sample()

        model.moveRows(3...3, to: 1)
        #expect(grid(model).map(\.first) == ["00", "30", "10", "20"])

        model.moveRows(1...1, to: 4)
        #expect(grid(model).map(\.first) == ["00", "10", "20", "30"])
    }

    @Test func theHeaderStaysFirst() {
        var model = sample()

        model.moveRows(0...0, to: 2)
        model.moveRows(2...2, to: 0)

        #expect(grid(model) == grid(sample()))
    }

    @Test func severalRowsMoveTogether() {
        var model = sample()

        model.moveRows(1...2, to: 4)

        #expect(grid(model).map(\.first) == ["00", "30", "10", "20"])
    }

    @Test func aColumnMovesWithItsAlignment() {
        var model = sample()

        model.moveColumns(0...0, to: 3)

        #expect(grid(model)[0] == ["01", "02", "00"])
        #expect(grid(model)[2] == ["21", "22", "20"])
        #expect(model.columns.map(\.alignment) == [.none, .none, .right])
    }

    @Test func aMoveOntoItselfChangesNothing() {
        var model = sample()

        model.moveColumns(1...1, to: 2)
        model.moveRows(2...2, to: 2)

        #expect(grid(model) == grid(sample()))
    }

    @Test func positionsFollowTheMove() {
        #expect(TableModel.movedRange(3...3, to: 1) == 1...1)
        #expect(TableModel.movedRange(1...2, to: 4) == 2...3)
        #expect((1...4).map { TableModel.position(of: $0, moving: 3...3, to: 1) } == [2, 3, 1, 4])
        #expect((1...4).map { TableModel.position(of: $0, moving: 1...1, to: 4) } == [3, 1, 2, 4])
    }
}
