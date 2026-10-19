import AppKit

final class MultiCaret {
    var extras: [Int] = []
    var isApplying = false
    var hiddenCaretColor: NSColor?
    let overlay = CaretOverlay()

    var isActive: Bool {
        extras.isEmpty == false
    }

    static func merged(_ positions: [Int], primary: Int, limit: Int) -> (primary: Int, extras: [Int]) {
        let clamped = positions.map { min(max($0, 0), limit) }
        let main = clamped[primary]
        let extras = Set(clamped.enumerated().filter { $0.offset != primary }.map(\.element)).subtracting([main])
        return (main, extras.sorted())
    }

    static func shifted(_ positions: [Int], editing index: Int, range: NSRange, insertedLength: Int) -> [Int] {
        var result = positions
        let delta = insertedLength - range.length
        for other in result.indices where other != index && result[other] >= NSMaxRange(range) {
            result[other] += delta
        }
        result[index] = range.location + insertedLength
        return result
    }
}
