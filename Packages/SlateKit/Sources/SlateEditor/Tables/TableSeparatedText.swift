import Foundation

enum TableSeparatedText {
    static func model(from text: String) -> TableModel? {
        let lines = text.replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .newlines)
            .components(separatedBy: "\n")
        let rows = lines.map { $0.components(separatedBy: "\t") }
        guard let first = rows.first, first.count > 1 else { return nil }
        let width = rows.map(\.count).max() ?? first.count
        let cells = rows.map { row in
            (row + Array(repeating: "", count: width - row.count)).map { value in
                TableCell(TableCellText.markdown(of: NSAttributedString(string: value.trimmingCharacters(in: .whitespaces))))
            }
        }
        return TableModel(columns: Array(repeating: TableColumn(), count: width), header: cells[0], rows: Array(cells.dropFirst()))
    }
}
