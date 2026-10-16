import Foundation

final class FenceTracker {
    private(set) var lines: [LineState] = []

    init(text: NSString) {
        reset(text: text)
    }

    func reset(text: NSString) {
        lines = Self.split(text, from: 0, to: text.length)
        _ = resolve(from: 0, through: lines.count - 1)
    }

    func lineIndex(containing location: Int) -> Int {
        var low = 0
        var high = lines.count - 1
        while low < high {
            let middle = (low + high + 1) / 2
            if lines[middle].start <= location {
                low = middle
            } else {
                high = middle - 1
            }
        }
        return low
    }

    func state(at location: Int) -> LineState {
        lines[lineIndex(containing: location)]
    }

    @discardableResult
    func update(text: NSString, editedRange: NSRange, changeInLength delta: Int) -> NSRange {
        guard lines.isEmpty == false else {
            reset(text: text)
            return NSRange(location: 0, length: text.length)
        }
        let oldEnd = editedRange.upperBound - delta
        let first = lineIndex(containing: editedRange.location)
        let lastOld = lineIndex(containing: max(oldEnd, editedRange.location))
        let start = lines[first].start
        let endNew = lines[lastOld].start + lines[lastOld].length + delta
        let replacement = Self.split(text, from: start, to: endNew)
        lines.replaceSubrange(first...lastOld, with: replacement)
        if delta != 0 {
            for index in (first + replacement.count)..<lines.count {
                lines[index].start += delta
            }
        }
        let last = resolve(from: first, through: first + replacement.count - 1)
        let end = lines[last].start + lines[last].length
        return NSRange(location: start, length: end - start)
    }

    private func resolve(from first: Int, through lastReplaced: Int) -> Int {
        var open = first > 0 ? lines[first - 1].openFence : nil
        var index = first
        while index < lines.count {
            let before = lines[index]
            var line = before
            if let fence = open {
                if let delimiter = line.delimiter, delimiter.closes(fence) {
                    line.kind = .fenceClose
                    open = nil
                } else {
                    line.kind = .code(language: fence.language)
                }
            } else if let delimiter = line.delimiter {
                line.kind = .fenceOpen(language: delimiter.language)
                open = delimiter
            } else {
                line.kind = line.base
            }
            line.openFence = open
            lines[index] = line
            if index > lastReplaced, line.kind == before.kind, line.openFence == before.openFence {
                return index - 1
            }
            index += 1
        }
        return lines.count - 1
    }

    private static func split(_ text: NSString, from start: Int, to end: Int) -> [LineState] {
        var result: [LineState] = []
        var lineStart = start
        while true {
            let searchRange = NSRange(location: lineStart, length: end - lineStart)
            let newline = text.range(of: "\n", options: .literal, range: searchRange)
            let lineEnd = newline.location == NSNotFound ? end : newline.location
            let range = NSRange(location: lineStart, length: lineEnd - lineStart)
            let string = text.substring(with: range)
            let base = MarkdownLineScanner.kind(of: string)
            result.append(LineState(start: lineStart, length: range.length, base: base, delimiter: FenceDelimiter.parse(string), kind: base, openFence: nil))
            guard newline.location != NSNotFound else { break }
            lineStart = lineEnd + 1
        }
        return result
    }
}
