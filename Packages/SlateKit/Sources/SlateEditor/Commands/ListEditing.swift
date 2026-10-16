import Foundation

enum ListEditing {
    static func newline(in text: NSString, selection: NSRange) -> TextEdit? {
        guard selection.length == 0 else { return nil }
        let lineRange = contentRange(of: text.lineRange(for: NSRange(location: selection.location, length: 0)), in: text)
        let line = text.substring(with: lineRange)
        let caretInLine = selection.location - lineRange.location
        let quote = quotePrefix(of: line)
        let rest = String(line.dropFirst(quote.count))
        if let item = MarkdownLineScanner.listItem(rest) {
            let prefixLength = (quote as NSString).length + item.contentStart
            guard caretInLine >= prefixLength else { return nil }
            let content = (rest as NSString).substring(from: item.contentStart)
            if content.trimmingCharacters(in: .whitespaces).isEmpty {
                return TextEdit(range: lineRange, replacement: quote, selection: NSRange(location: lineRange.location + (quote as NSString).length, length: 0))
            }
            return continuation(of: item, quote: quote, in: text, line: lineRange, caret: selection.location)
        }
        guard quote.isEmpty == false, caretInLine >= (quote as NSString).length else { return nil }
        if rest.trimmingCharacters(in: .whitespaces).isEmpty {
            return TextEdit(range: lineRange, replacement: "", selection: NSRange(location: lineRange.location, length: 0))
        }
        let insertion = "\n" + quote
        return TextEdit(range: selection, replacement: insertion, selection: NSRange(location: selection.location + (insertion as NSString).length, length: 0))
    }

    static func indent(in text: NSString, selection: NSRange, outdent: Bool) -> TextEdit? {
        let block = text.lineRange(for: selection)
        var lines: [String] = []
        var anyList = false
        var shiftFirst = 0
        var shiftTotal = 0
        var index = 0
        text.enumerateSubstrings(in: block, options: [.byLines, .substringNotRequired]) { _, lineRange, _, _ in
            let line = text.substring(with: lineRange)
            var changed = line
            if let item = MarkdownLineScanner.listItem(line) {
                anyList = true
                let unit = String(repeating: " ", count: item.markerLength + 1)
                if outdent {
                    let removable = line.prefix { $0 == " " }.count
                    let removed = line.hasPrefix("\t") ? 1 : min(removable, unit.count)
                    changed = String(line.dropFirst(removed))
                } else {
                    changed = unit + line
                }
            }
            let shift = (changed as NSString).length - lineRange.length
            if index == 0 { shiftFirst = shift }
            shiftTotal += shift
            lines.append(changed)
            index += 1
        }
        guard anyList else { return nil }
        let contentBlock = contentRange(of: block, in: text)
        let replacement = lines.joined(separator: "\n")
        let start = max(contentBlock.location, selection.location + shiftFirst)
        let length = max(0, selection.length + shiftTotal - shiftFirst)
        return TextEdit(range: contentBlock, replacement: replacement, selection: NSRange(location: start, length: selection.length == 0 ? 0 : length))
    }

    private static func continuation(of item: ListItem, quote: String, in text: NSString, line: NSRange, caret: Int) -> TextEdit {
        let indent = String(repeating: " ", count: item.indent)
        let checkbox = item.checkbox == nil ? "" : "[ ] "
        let lineEnd = line.upperBound
        let tail = text.substring(with: NSRange(location: caret, length: lineEnd - caret))
        guard case .ordered(let number, let delimiter) = item.marker else {
            let insertion = "\n" + quote + indent + item.markerText + " " + checkbox
            return TextEdit(range: NSRange(location: caret, length: 0), replacement: insertion, selection: NSRange(location: caret + (insertion as NSString).length, length: 0))
        }
        let head = "\n" + quote + indent + "\(number + 1)\(delimiter) " + checkbox
        var replacement = head + tail
        var end = lineEnd
        var next = number + 2
        while end < text.length {
            let nextLine = contentRange(of: text.lineRange(for: NSRange(location: end + 1, length: 0)), in: text)
            let string = text.substring(with: nextLine)
            let body = String(string.dropFirst(quote.count))
            guard string.hasPrefix(quote), let sibling = MarkdownLineScanner.listItem(body) else { break }
            if sibling.indent > item.indent {
                replacement += "\n" + string
            } else if sibling.indent == item.indent, case .ordered(_, let siblingDelimiter) = sibling.marker, siblingDelimiter == delimiter {
                let rest = (body as NSString).substring(from: sibling.indent + sibling.markerLength)
                replacement += "\n" + quote + indent + "\(next)\(delimiter)" + rest
                next += 1
            } else {
                break
            }
            end = nextLine.upperBound
        }
        return TextEdit(range: NSRange(location: caret, length: end - caret), replacement: replacement, selection: NSRange(location: caret + (head as NSString).length, length: 0))
    }

    static func quotePrefix(of line: String) -> String {
        guard line.hasPrefix(">") else { return "" }
        return line.hasPrefix("> ") ? "> " : ">"
    }

    static func contentRange(of lineRange: NSRange, in text: NSString) -> NSRange {
        var end = lineRange.upperBound
        while end > lineRange.location, text.character(at: end - 1) == 0x0A || text.character(at: end - 1) == 0x0D {
            end -= 1
        }
        return NSRange(location: lineRange.location, length: end - lineRange.location)
    }
}
