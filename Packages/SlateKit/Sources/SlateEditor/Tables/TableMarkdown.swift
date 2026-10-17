import Foundation

nonisolated package enum TableMarkdown {
    package static func parse(_ source: String) -> TableModel? {
        let lines = source.components(separatedBy: "\n")
        guard lines.count >= 2, lines[0].contains("|"), lines[1].contains("|") else { return nil }
        let header = cells(of: lines[0])
        let markers = cells(of: lines[1])
        guard header.isEmpty == false, header.count == markers.count else { return nil }
        let alignments = markers.compactMap(alignment)
        guard alignments.count == markers.count else { return nil }
        var rows: [[TableCell]] = []
        for line in lines.dropFirst(2) {
            let row = cells(of: line)
            guard row.count == header.count else { return nil }
            rows.append(row.map(TableCell.init))
        }
        return TableModel(columns: alignments.map(TableColumn.init), header: header.map(TableCell.init), rows: rows)
    }

    package static func render(_ model: TableModel) -> String {
        var lines = [line(model.header.map(\.markdown))]
        lines.append(line(model.columns.map(\.alignment.marker), escapes: false))
        for row in model.rows {
            lines.append(line(row.map(\.markdown)))
        }
        return lines.joined(separator: "\n")
    }

    package static func looksLikeTable(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("\n") && parse(trimmed) != nil
    }

    static func cells(of line: String) -> [String] {
        var text = line.trimmingCharacters(in: .whitespaces)
        guard text.isEmpty == false else { return [] }
        if text.hasPrefix("|") { text.removeFirst() }
        if text.hasSuffix("|"), isEscaped(text, before: text.index(before: text.endIndex)) == false { text.removeLast() }
        var cells: [String] = []
        var current = ""
        var backslashes = 0
        for character in text {
            if character == "|", backslashes % 2 == 0 {
                cells.append(current)
                current = ""
                backslashes = 0
                continue
            }
            backslashes = character == "\\" ? backslashes + 1 : 0
            current.append(character)
        }
        cells.append(current)
        return cells.map { unescapePipes($0.trimmingCharacters(in: .whitespaces)) }
    }

    private static func isEscaped(_ text: String, before index: String.Index) -> Bool {
        var count = 0
        var position = index
        while position > text.startIndex {
            position = text.index(before: position)
            guard text[position] == "\\" else { break }
            count += 1
        }
        return count % 2 == 1
    }

    private static func alignment(_ marker: String) -> TableAlignment? {
        let leading = marker.hasPrefix(":")
        let trailing = marker.hasSuffix(":") && marker.count > 1
        let dashes = marker.dropFirst(leading ? 1 : 0).dropLast(trailing ? 1 : 0)
        guard dashes.isEmpty == false, dashes.allSatisfy({ $0 == "-" }) else { return nil }
        switch (leading, trailing) {
        case (true, true): return .center
        case (true, false): return .left
        case (false, true): return .right
        case (false, false): return TableAlignment.none
        }
    }

    private static func unescapePipes(_ text: String) -> String {
        let characters = Array(text)
        var output = ""
        var index = 0
        while index < characters.count {
            if characters[index] == "\\", index + 1 < characters.count, characters[index + 1] == "|" {
                output.append("|")
                index += 2
                continue
            }
            output.append(characters[index])
            index += 1
        }
        return output
    }

    static func escapePipes(_ text: String) -> String {
        var output = ""
        var backslashes = 0
        for character in text {
            if character == "|" {
                if backslashes % 2 == 0 { output.append("\\") }
                output.append("|")
                backslashes = 0
                continue
            }
            backslashes = character == "\\" ? backslashes + 1 : 0
            output.append(character)
        }
        return output
    }

    private static func line(_ cells: [String], escapes: Bool = true) -> String {
        "|" + cells.map { cell in
            let text = escapes ? escapePipes(cell) : cell
            return text.isEmpty ? " " : " \(text) "
        }.joined(separator: "|") + "|"
    }
}
