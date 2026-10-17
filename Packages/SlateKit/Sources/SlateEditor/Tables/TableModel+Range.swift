import Foundation

extension TableModel {
    func slice(_ range: TableCellRange) -> TableModel {
        let rows = range.rows.map { row in range.columns.map { cell(TableCellIndex(row: row, column: $0)) } }
        let columns = range.columns.map { $0 < self.columns.count ? self.columns[$0] : TableColumn() }
        return TableModel(columns: columns, header: rows.first ?? [], rows: Array(rows.dropFirst()))
    }

    mutating func clear(_ range: TableCellRange) {
        for index in range.indexes {
            setCell(index, markdown: "")
        }
    }

    mutating func paste(_ source: TableModel, at origin: TableCellIndex) {
        let lines = source.allRows
        while columnCount < origin.column + source.columnCount {
            insertColumn(at: columnCount)
        }
        while rowCount < origin.row + lines.count {
            insertRow(at: rowCount)
        }
        for (rowOffset, line) in lines.enumerated() {
            for (columnOffset, cell) in line.enumerated() {
                setCell(TableCellIndex(row: origin.row + rowOffset, column: origin.column + columnOffset), markdown: cell.markdown)
            }
        }
    }

    mutating func deleteRows(_ range: ClosedRange<Int>) {
        let body = range.filter { $0 >= 1 && $0 < rowCount }
        for row in body.reversed() {
            deleteRow(row)
        }
        if rows.isEmpty {
            insertRow(at: 1)
        }
    }

    mutating func deleteColumns(_ range: ClosedRange<Int>) {
        let columns = range.filter { $0 >= 0 && $0 < columnCount }
        for column in columns.reversed() where columnCount > 1 {
            deleteColumn(column)
        }
    }

    mutating func setAlignment(_ alignment: TableAlignment, columns range: ClosedRange<Int>) {
        for column in range {
            setAlignment(alignment, column: column)
        }
    }

    @MainActor
    mutating func toggle(_ flag: InlineStyle, in range: TableCellRange) {
        let texts = range.indexes.map { index in
            (index, NSMutableAttributedString(attributedString: TableCellText.inline(cell(index).markdown) ?? NSAttributedString(string: cell(index).markdown)))
        }
        let all = texts.allSatisfy { _, text in Self.has(flag, in: text) }
        for (index, text) in texts where text.length > 0 {
            text.enumerateAttribute(.slateInline, in: NSRange(location: 0, length: text.length)) { value, part, _ in
                guard text.attribute(.slateImagePath, at: part.location, effectiveRange: nil) == nil else { return }
                var inline = InlineStyle(rawValue: value as? Int ?? 0)
                if all { inline.remove(flag) } else { inline.insert(flag) }
                if inline.isEmpty {
                    text.removeAttribute(.slateInline, range: part)
                } else {
                    text.addAttribute(.slateInline, value: inline.rawValue, range: part)
                }
            }
            setCell(index, markdown: TableCellText.markdown(of: text))
        }
    }

    private static func has(_ flag: InlineStyle, in text: NSAttributedString) -> Bool {
        var found = true
        var any = false
        text.enumerateAttribute(.slateInline, in: NSRange(location: 0, length: text.length)) { value, part, stop in
            let string = (text.string as NSString).substring(with: part)
            guard string.trimmingCharacters(in: .whitespaces).isEmpty == false,
                  text.attribute(.slateImagePath, at: part.location, effectiveRange: nil) == nil else { return }
            any = true
            if InlineStyle(rawValue: value as? Int ?? 0).contains(flag) == false {
                found = false
                stop.pointee = true
            }
        }
        return found || any == false
    }
}
