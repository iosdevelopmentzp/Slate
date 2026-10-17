import Foundation

nonisolated package struct TableModel: Hashable, Sendable {
    package var columns: [TableColumn]
    package var header: [TableCell]
    package var rows: [[TableCell]]

    package init(columns: [TableColumn], header: [TableCell], rows: [[TableCell]]) {
        self.columns = columns
        self.header = header
        self.rows = rows
    }

    package static func empty(columns: Int = 2, rows: Int = 1) -> TableModel {
        TableModel(
            columns: Array(repeating: TableColumn(), count: columns),
            header: Array(repeating: TableCell(), count: columns),
            rows: Array(repeating: Array(repeating: TableCell(), count: columns), count: rows)
        )
    }

    package var columnCount: Int {
        columns.count
    }

    package var rowCount: Int {
        rows.count + 1
    }

    package var allRows: [[TableCell]] {
        [header] + rows
    }

    package var filledCellCount: Int {
        allRows.joined().filter { $0.isEmpty == false }.count
    }

    package func cell(_ index: TableCellIndex) -> TableCell {
        guard contains(index) else { return TableCell() }
        return index.row == 0 ? header[index.column] : rows[index.row - 1][index.column]
    }

    package func contains(_ index: TableCellIndex) -> Bool {
        index.row >= 0 && index.row < rowCount && index.column >= 0 && index.column < columnCount
    }

    package mutating func setCell(_ index: TableCellIndex, markdown: String) {
        guard contains(index) else { return }
        if index.row == 0 {
            header[index.column].markdown = markdown
        } else {
            rows[index.row - 1][index.column].markdown = markdown
        }
    }

    package mutating func insertRow(at row: Int) {
        let position = min(max(row, 1), rowCount)
        rows.insert(Array(repeating: TableCell(), count: columnCount), at: position - 1)
    }

    package mutating func deleteRow(_ row: Int) {
        guard row >= 1, row < rowCount else { return }
        rows.remove(at: row - 1)
    }

    package mutating func insertColumn(at column: Int) {
        let position = min(max(column, 0), columnCount)
        columns.insert(TableColumn(), at: position)
        header.insert(TableCell(), at: position)
        for index in rows.indices {
            rows[index].insert(TableCell(), at: position)
        }
    }

    package mutating func deleteColumn(_ column: Int) {
        guard column >= 0, column < columnCount, columnCount > 1 else { return }
        columns.remove(at: column)
        header.remove(at: column)
        for index in rows.indices {
            rows[index].remove(at: column)
        }
    }

    package mutating func setAlignment(_ alignment: TableAlignment, column: Int) {
        guard column >= 0, column < columnCount else { return }
        columns[column].alignment = alignment
    }
}
