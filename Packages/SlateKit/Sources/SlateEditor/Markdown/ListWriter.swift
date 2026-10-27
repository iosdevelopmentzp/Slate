import Foundation

enum ListWriter {

    static func write(_ items: [WriterParagraph], alternate: Bool) -> String {
        var lines: [String] = []
        var contentStarts: [Int] = []
        var numbers: [Int] = []
        var kinds: [BlockKind] = []
        for item in items {
            if item.block.kind == .image {
                let level = min(item.block.indent, contentStarts.count)
                contentStarts = Array(contentStarts.prefix(level))
                numbers = Array(numbers.prefix(level))
                kinds = Array(kinds.prefix(level))
                guard let image = MarkdownWriter.image(item.block) else { continue }
                if lines.isEmpty == false, lines.last?.isEmpty == false { lines.append("") }
                lines.append(String(repeating: " ", count: contentStarts.last ?? 0) + image)
                lines.append("")
                continue
            }
            let level = min(item.block.indent, contentStarts.count)
            contentStarts = Array(contentStarts.prefix(level))
            numbers = Array(numbers.prefix(level + 1))
            kinds = Array(kinds.prefix(level + 1))
            let indent = contentStarts.last ?? 0
            let number: Int
            if numbers.count == level + 1, kinds[level] == .numbered, item.block.kind == .numbered {
                number = numbers[level] + 1
                numbers[level] = number
                kinds[level] = .numbered
            } else {
                number = 1
                numbers = Array(numbers.prefix(level)) + [1]
                kinds = Array(kinds.prefix(level)) + [item.block.kind]
            }
            let bullet = alternate && level == 0 ? "*" : "-"
            let marker: String
            switch item.block.kind {
            case .numbered: marker = "\(number)" + (alternate && level == 0 ? ")" : ".") + " "
            case .checklist: marker = bullet + (item.block.isDone ? " [x] " : " [ ] ")
            default: marker = bullet + " "
            }
            let markerWidth = item.block.kind == .numbered ? marker.count : 2
            let padding = String(repeating: " ", count: indent)
            let content = InlineWriter.lines(of: item.text)
            lines.append(padding + marker + (content.first ?? ""))
            let continuation = String(repeating: " ", count: indent + markerWidth)
            for line in content.dropFirst() {
                lines.append(line.isEmpty ? "" : continuation + line)
            }
            contentStarts.append(indent + markerWidth)
        }
        while lines.last?.isEmpty == true { lines.removeLast() }
        return lines.map { $0.trailingSpacesRemoved }.joined(separator: "\n")
    }
}
