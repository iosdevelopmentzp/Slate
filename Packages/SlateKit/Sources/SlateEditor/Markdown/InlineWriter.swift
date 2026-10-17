import Foundation

enum InlineWriter {

    static func lines(of text: NSAttributedString) -> [String] {
        let cells = InlineCell.cells(of: text)
        var lines: [String] = []
        var current: [InlineCell] = []
        for cell in cells {
            if cell.character == RichText.lineBreak {
                lines.append(render(current) + (cell.isHardBreak ? "\\" : ""))
                current = []
            } else {
                current.append(cell)
            }
        }
        lines.append(render(current))
        return lines.map { $0.trailingSpacesRemoved }
    }

    static func render(_ cells: [InlineCell]) -> String {
        let trimmed = trimmedLine(cells)
        let shaped = moveSpacesOutOfStyles(trimmed)
        var output = ""
        var index = 0
        while index < shaped.count {
            let href = shaped[index].href
            var end = index
            while end < shaped.count, shaped[end].href == href { end += 1 }
            let segment = Array(shaped[index..<end])
            if let href {
                output += link(segment, href: href, context: shaped, offset: index)
            } else {
                output += styled(segment, context: shaped, offset: index, inLabel: false)
            }
            index = end
        }
        return output
    }

    private static func trimmedLine(_ cells: [InlineCell]) -> [InlineCell] {
        var start = 0
        var end = cells.count
        while start < end, cells[start].isCode == false, cells[start].character == " " || cells[start].character == "\t" { start += 1 }
        while end > start, cells[end - 1].isCode == false, cells[end - 1].character == " " || cells[end - 1].character == "\t" { end -= 1 }
        return Array(cells[start..<end])
    }

    private static func moveSpacesOutOfStyles(_ cells: [InlineCell]) -> [InlineCell] {
        var result = cells
        for flag in [InlineStyle.bold, .italic, .strikethrough] {
            var index = 0
            while index < result.count {
                guard result[index].style.contains(flag) else {
                    index += 1
                    continue
                }
                var end = index
                while end < result.count, result[end].style.contains(flag) { end += 1 }
                var left = index
                while left < end, result[left].character.isWhitespace, result[left].isCode == false {
                    result[left].style.remove(flag)
                    left += 1
                }
                var right = end - 1
                while right >= left, result[right].character.isWhitespace, result[right].isCode == false {
                    result[right].style.remove(flag)
                    right -= 1
                }
                index = end
            }
        }
        return result
    }

    private static func link(_ segment: [InlineCell], href: String, context: [InlineCell], offset: Int) -> String {
        let label = segment.map { String($0.character) }.joined()
        if href.hasPrefix(RichText.wikiPrefix) {
            let target = String(href.dropFirst(RichText.wikiPrefix.count))
            return label == target || label.isEmpty ? "[[\(target)]]" : "[[\(target)|\(label)]]"
        }
        let inner = styled(segment, context: context, offset: offset, inLabel: true)
        return "[\(inner)](\(destination(href)))"
    }

    private static func styled(_ segment: [InlineCell], context: [InlineCell], offset: Int, inLabel: Bool) -> String {
        var output = ""
        var open: [InlineStyle] = []
        var index = 0
        while index < segment.count {
            let style = segment[index].style
            var end = index
            while end < segment.count, segment[end].style == style { end += 1 }
            let wanted = [InlineStyle.bold, .italic, .strikethrough].filter { style.contains($0) }
            var keep = 0
            while keep < open.count, keep < wanted.count, open[keep] == wanted[keep] { keep += 1 }
            for flag in open[keep...].reversed() { output += delimiter(flag) }
            open = Array(open.prefix(keep))
            for flag in wanted[keep...] {
                output += delimiter(flag)
                open.append(flag)
            }
            let run = Array(segment[index..<end])
            if style.contains(.code) {
                output += codeSpan(run.map { String($0.character) }.joined())
            } else {
                for (position, cell) in run.enumerated() {
                    if let path = cell.imagePath {
                        output += "![\(escapeLabel(cell.imageAlt ?? ""))](\(destination(path)))"
                        continue
                    }
                    output += escape(cell.character, at: offset + index + position, in: context, inLabel: inLabel)
                }
            }
            index = end
        }
        for flag in open.reversed() { output += delimiter(flag) }
        return output
    }

    private static func delimiter(_ flag: InlineStyle) -> String {
        switch flag {
        case .bold: "**"
        case .italic: "*"
        default: "~~"
        }
    }

    static func codeSpan(_ code: String) -> String {
        var longest = 0
        var current = 0
        for character in code {
            current = character == "`" ? current + 1 : 0
            longest = max(longest, current)
        }
        let fence = String(repeating: "`", count: longest + 1)
        let needsPadding = code.hasPrefix("`") || code.hasSuffix("`") || (code.hasPrefix(" ") && code.hasSuffix(" ") && code.contains { $0 != " " })
        let padding = needsPadding ? " " : ""
        return fence + padding + code + padding + fence
    }

    private static func escape(_ character: Character, at index: Int, in cells: [InlineCell], inLabel: Bool) -> String {
        let previous = index > 0 ? cells[index - 1].character : nil
        let next = index + 1 < cells.count ? cells[index + 1].character : nil
        let text = String(character)
        if index == 0, let escaped = lineStartEscape(character) {
            return escaped
        }
        switch character {
        case "*", "`", "[", "]", "<", "~":
            return "\\" + text
        case "\\":
            guard let next else { return "\\\\" }
            return next.isASCII && next.isPunctuation || next.isASCII && next.isSymbol ? "\\\\" : text
        case "_":
            let inside = previous.map(isWordCharacter) == true && next.map(isWordCharacter) == true
            return inside ? text : "\\_"
        case "&":
            return startsEntity(at: index + 1, in: cells) ? "\\&" : text
        case ".", ")":
            return endsListNumber(at: index, in: cells) ? "\\" + text : text
        default:
            return text
        }
    }

    private static func lineStartEscape(_ character: Character) -> String? {
        switch character {
        case "#", ">", "-", "+", "=", "|", "*", "`", "~", "[", "<", "_":
            "\\" + String(character)
        default:
            nil
        }
    }

    private static func endsListNumber(at index: Int, in cells: [InlineCell]) -> Bool {
        guard index > 0, index <= 9 else { return false }
        return cells[0..<index].allSatisfy { $0.character.isASCII && $0.character.isNumber }
    }

    private static func isWordCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber
    }

    private static func startsEntity(at index: Int, in cells: [InlineCell]) -> Bool {
        guard index < cells.count else { return false }
        if cells[index].character == "#" { return true }
        var position = index
        while position < cells.count, cells[position].character.isASCII, cells[position].character.isLetter { position += 1 }
        return position > index && position < cells.count && cells[position].character == ";"
    }

    static func escapeLabel(_ text: String) -> String {
        var output = ""
        for character in text {
            switch character {
            case "\\", "[", "]", "*", "_", "`", "<", "~":
                output += "\\" + String(character)
            default:
                output.append(character)
            }
        }
        return output
    }

    static func destination(_ href: String) -> String {
        let needsBrackets = href.contains { $0 == " " || $0 == "(" || $0 == ")" || $0 == "<" || $0 == ">" || $0.isWhitespace }
        guard needsBrackets else { return href }
        let escaped = href.replacingOccurrences(of: "<", with: "\\<").replacingOccurrences(of: ">", with: "\\>")
        return "<\(escaped)>"
    }
}
