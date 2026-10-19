import AppKit

extension TableLayout {
    static let gripLength: CGFloat = 18
    static let gripThickness: CGFloat = 4
    static let dot: CGFloat = 14
    static let reach: CGFloat = 6
    static let edge: CGFloat = 18

    func rowTop(_ row: Int) -> CGFloat {
        rowHeights.prefix(row).reduce(0, +)
    }

    func columnLeft(_ column: Int) -> CGFloat {
        columnWidths.prefix(column).reduce(0, +)
    }

    func rect(of grip: TableGrip) -> CGRect {
        switch grip {
        case .row(let row):
            let cell = cellRect(TableCellIndex(row: row, column: 0))
            let length = min(Self.gripLength, max(cell.height - 8, 6))
            return CGRect(x: 1.5, y: cell.midY - length / 2, width: Self.gripThickness, height: length)
        case .column(let column):
            let cell = cellRect(TableCellIndex(row: 0, column: column))
            let length = min(Self.gripLength, max(cell.width - 8, 6))
            return CGRect(x: cell.midX - length / 2, y: 1.5, width: length, height: Self.gripThickness)
        case .insertRow(let row):
            return CGRect(x: 0, y: rowTop(row) - Self.dot / 2, width: Self.dot, height: Self.dot)
        case .insertColumn(let column):
            return CGRect(x: max(columnLeft(column) - Self.dot / 2, 0), y: 0, width: Self.dot, height: Self.dot)
        }
    }

    func grips(near point: CGPoint) -> [TableGrip] {
        guard rowHeights.isEmpty == false, columnWidths.isEmpty == false, point.x >= -Self.reach, point.y >= -Self.reach, point.x <= size.width + Self.reach, point.y <= size.height + Self.reach else { return [] }
        var result: [TableGrip] = []
        if point.x <= Self.edge, let row = (1...rowHeights.count).first(where: { abs(point.y - rowTop($0)) <= Self.reach }) {
            result.append(.insertRow(row))
        }
        if point.y <= Self.edge, let column = (0...columnWidths.count).first(where: { abs(point.x - columnLeft($0)) <= Self.reach }) {
            result.append(.insertColumn(column))
        }
        if let cell = cell(at: point) {
            if cell.row > 0 { result.append(.row(cell.row)) }
            result.append(.column(cell.column))
        }
        return result
    }

    func grip(at point: CGPoint) -> TableGrip? {
        grips(near: point).first { rect(of: $0).insetBy(dx: -3, dy: -3).contains(point) }
    }

    func rowInsertion(atY y: CGFloat) -> Int {
        guard rowHeights.count > 1 else { return 1 }
        return (1...rowHeights.count).min { abs(y - rowTop($0)) < abs(y - rowTop($1)) } ?? 1
    }

    func columnInsertion(atX x: CGFloat) -> Int {
        (0...columnWidths.count).min { abs(x - columnLeft($0)) < abs(x - columnLeft($1)) } ?? 0
    }
}
