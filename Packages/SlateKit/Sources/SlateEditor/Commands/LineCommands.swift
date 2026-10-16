import Foundation

enum LineCommands {
    static func moveLines(in text: NSString, selection: NSRange, up: Bool) -> TextEdit? {
        let block = text.lineRange(for: selection)
        if up {
            guard block.location > 0 else { return nil }
            let previous = text.lineRange(for: NSRange(location: block.location - 1, length: 0))
            let blockText = terminated(text.substring(with: block))
            let previousText = terminated(text.substring(with: previous))
            let joined = blockText + previousText
            let range = NSRange(location: previous.location, length: previous.length + block.length)
            let replacement = trimmedEnd(joined, like: text.substring(with: range))
            return TextEdit(range: range, replacement: replacement, selection: NSRange(location: selection.location - previous.length, length: selection.length))
        }
        guard block.upperBound < text.length else { return nil }
        let next = text.lineRange(for: NSRange(location: block.upperBound, length: 0))
        let blockText = terminated(text.substring(with: block))
        let nextText = terminated(text.substring(with: next))
        let range = NSRange(location: block.location, length: block.length + next.length)
        let replacement = trimmedEnd(nextText + blockText, like: text.substring(with: range))
        return TextEdit(range: range, replacement: replacement, selection: NSRange(location: selection.location + (nextText as NSString).length, length: selection.length))
    }

    static func duplicateLines(in text: NSString, selection: NSRange) -> TextEdit {
        let block = text.lineRange(for: selection)
        let blockText = text.substring(with: block)
        let hasNewline = blockText.hasSuffix("\n")
        let insertion = hasNewline ? blockText : "\n" + blockText
        let location = block.upperBound
        let shift = (insertion as NSString).length
        return TextEdit(range: NSRange(location: location, length: 0), replacement: insertion, selection: NSRange(location: selection.location + shift, length: selection.length))
    }

    static func toggleComment(in text: NSString, selection: NSRange, prefix: String) -> TextEdit {
        let block = ListEditing.contentRange(of: text.lineRange(for: selection), in: text)
        let lines = text.substring(with: block).components(separatedBy: "\n")
        let marker = prefix + " "
        let filled = lines.filter { $0.trimmingCharacters(in: .whitespaces).isEmpty == false }
        let allCommented = filled.isEmpty == false && filled.allSatisfy { $0.trimmingCharacters(in: .whitespaces).hasPrefix(prefix) }
        let indent = filled.map { $0.prefix { $0 == " " || $0 == "\t" }.count }.min() ?? 0
        let changed = lines.map { line -> String in
            guard line.trimmingCharacters(in: .whitespaces).isEmpty == false else { return line }
            if allCommented {
                let leading = line.prefix { $0 == " " || $0 == "\t" }
                var rest = line.dropFirst(leading.count)
                if rest.hasPrefix(marker) { rest = rest.dropFirst(marker.count) } else if rest.hasPrefix(prefix) { rest = rest.dropFirst(prefix.count) }
                return String(leading) + String(rest)
            }
            let index = line.index(line.startIndex, offsetBy: min(indent, line.count))
            return String(line[..<index]) + marker + String(line[index...])
        }
        let replacement = changed.joined(separator: "\n")
        let delta = (replacement as NSString).length - block.length
        let newSelection = selection.length == 0
            ? NSRange(location: max(block.location, selection.location + (allCommented ? -min((marker as NSString).length, selection.location - block.location) : (marker as NSString).length)), length: 0)
            : NSRange(location: block.location, length: block.length + delta)
        return TextEdit(range: block, replacement: replacement, selection: newSelection)
    }

    static func commentPrefix(for language: String) -> String {
        switch CodeHighlighter.language(named: language).name {
        case "yaml", "bash": "#"
        case "plain", "log", "diff": "//"
        default: "//"
        }
    }

    private static func terminated(_ line: String) -> String {
        line.hasSuffix("\n") ? line : line + "\n"
    }

    private static func trimmedEnd(_ text: String, like original: String) -> String {
        guard original.hasSuffix("\n") == false, text.hasSuffix("\n") else { return text }
        return String(text.dropLast())
    }
}
