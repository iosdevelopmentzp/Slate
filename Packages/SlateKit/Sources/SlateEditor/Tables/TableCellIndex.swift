import Foundation

nonisolated package struct TableCellIndex: Hashable, Sendable {
    package var row: Int
    package var column: Int

    package init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}
