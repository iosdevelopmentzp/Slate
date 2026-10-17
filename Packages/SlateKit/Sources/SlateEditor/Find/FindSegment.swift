import Foundation

nonisolated struct FindSegment: Equatable, Sendable {
    enum Place: Equatable, Sendable {
        case text(NSRange)
        case cell(table: Int, index: TableCellIndex)
    }

    let range: NSRange
    let string: String
    let place: Place
    let group: NSRange
}
