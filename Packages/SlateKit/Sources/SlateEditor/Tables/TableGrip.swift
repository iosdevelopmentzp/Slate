import Foundation

enum TableGrip: Equatable {
    case row(Int)
    case column(Int)
    case insertRow(Int)
    case insertColumn(Int)

    var isInsertion: Bool {
        switch self {
        case .insertRow, .insertColumn: true
        case .row, .column: false
        }
    }
}
