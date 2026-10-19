import Foundation

extension TableModel {
    static func movedRange(_ range: ClosedRange<Int>, to destination: Int) -> ClosedRange<Int> {
        let start = destination > range.upperBound ? destination - range.count : destination
        return start...(start + range.count - 1)
    }

    static func position(of index: Int, moving range: ClosedRange<Int>, to destination: Int) -> Int {
        let moved = movedRange(range, to: destination)
        if range.contains(index) {
            return moved.lowerBound + index - range.lowerBound
        }
        let rest = index > range.upperBound ? index - range.count : index
        return rest >= moved.lowerBound ? rest + range.count : rest
    }

    func canMoveRows(_ range: ClosedRange<Int>, to destination: Int) -> Bool {
        range.lowerBound >= 1 && range.upperBound < rowCount && (1...rowCount).contains(destination)
            && (range.lowerBound...(range.upperBound + 1)).contains(destination) == false
    }

    func canMoveColumns(_ range: ClosedRange<Int>, to destination: Int) -> Bool {
        range.lowerBound >= 0 && range.upperBound < columnCount && (0...columnCount).contains(destination)
            && (range.lowerBound...(range.upperBound + 1)).contains(destination) == false
    }

    mutating func moveRows(_ range: ClosedRange<Int>, to destination: Int) {
        guard canMoveRows(range, to: destination) else { return }
        let body = (range.lowerBound - 1)...(range.upperBound - 1)
        let moving = Array(rows[body])
        rows.removeSubrange(body)
        rows.insert(contentsOf: moving, at: Self.movedRange(range, to: destination).lowerBound - 1)
    }

    mutating func moveColumns(_ range: ClosedRange<Int>, to destination: Int) {
        guard canMoveColumns(range, to: destination) else { return }
        let start = Self.movedRange(range, to: destination).lowerBound
        columns = Self.moving(columns, range, to: start)
        header = Self.moving(header, range, to: start)
        rows = rows.map { Self.moving($0, range, to: start) }
    }

    private static func moving<Element>(_ items: [Element], _ range: ClosedRange<Int>, to start: Int) -> [Element] {
        var result = items
        let moving = Array(result[range])
        result.removeSubrange(range)
        result.insert(contentsOf: moving, at: start)
        return result
    }
}
