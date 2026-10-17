import Foundation

nonisolated struct TableCellRange: Equatable, Sendable {
    var anchor: TableCellIndex
    var head: TableCellIndex

    var rows: ClosedRange<Int> {
        min(anchor.row, head.row)...max(anchor.row, head.row)
    }

    var columns: ClosedRange<Int> {
        min(anchor.column, head.column)...max(anchor.column, head.column)
    }

    var topLeft: TableCellIndex {
        TableCellIndex(row: rows.lowerBound, column: columns.lowerBound)
    }

    var isSingle: Bool {
        anchor == head
    }

    var indexes: [TableCellIndex] {
        rows.flatMap { row in columns.map { TableCellIndex(row: row, column: $0) } }
    }

    func contains(_ index: TableCellIndex) -> Bool {
        rows.contains(index.row) && columns.contains(index.column)
    }

    func clamped(to model: TableModel) -> TableCellRange? {
        guard model.rowCount > 0, model.columnCount > 0 else { return nil }
        func clamp(_ index: TableCellIndex) -> TableCellIndex {
            TableCellIndex(row: min(index.row, model.rowCount - 1), column: min(index.column, model.columnCount - 1))
        }
        return TableCellRange(anchor: clamp(anchor), head: clamp(head))
    }
}
