import AppKit

nonisolated struct TableLayout: Equatable {
    static let padding = CGSize(width: 8, height: 6)
    static let minimumColumn: CGFloat = 60
    static let readableColumn: CGFloat = 120
    static let radius: CGFloat = 8
    static let handle: CGFloat = 20

    var columnWidths: [CGFloat]
    var rowHeights: [CGFloat]

    var size: CGSize {
        CGSize(width: columnWidths.reduce(0, +), height: rowHeights.reduce(0, +))
    }

    static func make(texts: [[NSAttributedString]], available: CGFloat, lineHeight: CGFloat) -> TableLayout {
        let columns = texts.first?.count ?? 0
        guard columns > 0 else { return TableLayout(columnWidths: [], rowHeights: []) }
        var widths = (0..<columns).map { column in
            texts.map { ceil($0[column].size().width) + padding.width * 2 }.max().map { max($0, minimumColumn) } ?? minimumColumn
        }
        let total = widths.reduce(0, +)
        if total > available {
            let floors = widths.map { min($0, readableColumn) }
            let reducible = zip(widths, floors).map { $0 - $1 }
            let room = reducible.reduce(0, +)
            let excess = min(total - available, room)
            if room > 0, excess > 0 {
                widths = zip(widths, reducible).map { width, spare in (width - excess * spare / room).rounded(.down) }
            }
        }
        let heights = texts.map { row in
            zip(row, widths).map { text, width in
                let bounds = text.boundingRect(with: CGSize(width: max(width - padding.width * 2, 1), height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading])
                return ceil(max(bounds.height, lineHeight)) + padding.height * 2
            }.max() ?? lineHeight + padding.height * 2
        }
        return TableLayout(columnWidths: widths, rowHeights: heights)
    }

    func cellRect(_ index: TableCellIndex) -> CGRect {
        guard index.column < columnWidths.count, index.row < rowHeights.count else { return .zero }
        let x = columnWidths.prefix(index.column).reduce(0, +)
        let y = rowHeights.prefix(index.row).reduce(0, +)
        return CGRect(x: x, y: y, width: columnWidths[index.column], height: rowHeights[index.row])
    }

    func textRect(_ index: TableCellIndex) -> CGRect {
        cellRect(index).insetBy(dx: Self.padding.width, dy: Self.padding.height)
    }

    func cell(at point: CGPoint) -> TableCellIndex? {
        guard point.x >= 0, point.y >= 0 else { return nil }
        var x: CGFloat = 0
        var column: Int?
        for (index, width) in columnWidths.enumerated() {
            if point.x < x + width {
                column = index
                break
            }
            x += width
        }
        var y: CGFloat = 0
        var row: Int?
        for (index, height) in rowHeights.enumerated() {
            if point.y < y + height {
                row = index
                break
            }
            y += height
        }
        guard let row, let column else { return nil }
        return TableCellIndex(row: row, column: column)
    }

    func column(atX x: CGFloat) -> Int {
        var edge: CGFloat = 0
        for (index, width) in columnWidths.enumerated() {
            edge += width
            if x < edge { return index }
        }
        return max(columnWidths.count - 1, 0)
    }
}
