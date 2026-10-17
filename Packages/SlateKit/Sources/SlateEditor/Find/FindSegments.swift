import AppKit

nonisolated struct FindSegments: Sendable {
    static let empty = FindSegments(items: [], length: 0)

    let items: [FindSegment]
    let length: Int

    @MainActor
    static func make(_ storage: NSAttributedString) -> FindSegments {
        var builder = Builder(string: storage.string as NSString)
        storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: storage.length)) { value, range, _ in
            guard let table = value as? TableAttachment else { return }
            builder.addText(upTo: range.location)
            builder.addTable(table, at: range.location)
        }
        builder.addText(upTo: storage.length)
        return FindSegments(items: builder.items, length: builder.offset)
    }

    func segment(at index: Int) -> FindSegment? {
        items.first { $0.range.location <= index && index < NSMaxRange($0.range) } ?? items.last { NSMaxRange($0.range) == index }
    }

    func virtualLocation(ofStorage location: Int) -> Int {
        for item in items {
            switch item.place {
            case .text(let range) where range.location <= location && location <= NSMaxRange(range):
                return item.range.location + location - range.location
            case .text(let range) where range.location > location:
                return item.range.location
            case .cell(let table, _) where table >= location:
                return item.range.location
            default:
                continue
            }
        }
        return length
    }

    func local(_ range: NSRange) -> (FindSegment, NSRange)? {
        guard let item = segment(at: range.location) else { return nil }
        let start = range.location - item.range.location
        let length = min(range.length, item.range.length - start)
        return (item, NSRange(location: start, length: max(length, 0)))
    }

    @MainActor
    private struct Builder {
        let string: NSString
        var items: [FindSegment] = []
        var offset = 0
        var cursor = 0

        mutating func addText(upTo end: Int) {
            defer { cursor = end + 1 }
            guard end > cursor else { return }
            let range = NSRange(location: cursor, length: end - cursor)
            let virtual = NSRange(location: offset, length: range.length)
            items.append(FindSegment(range: virtual, string: string.substring(with: range), place: .text(range), group: virtual))
            offset += range.length
        }

        mutating func addTable(_ table: TableAttachment, at location: Int) {
            let start = offset
            var cells: [(NSRange, String, TableCellIndex)] = []
            for row in 0..<table.model.rowCount {
                for column in 0..<table.model.columnCount {
                    let index = TableCellIndex(row: row, column: column)
                    let text = table.text(index).string
                    let length = (text as NSString).length
                    guard length > 0 else { continue }
                    cells.append((NSRange(location: offset, length: length), text, index))
                    offset += length
                }
            }
            let group = NSRange(location: start, length: offset - start)
            items += cells.map { FindSegment(range: $0.0, string: $0.1, place: .cell(table: location, index: $0.2), group: group) }
        }
    }
}
