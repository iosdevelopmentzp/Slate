import Foundation

enum FenceCompletion {
    static func closingFence(afterLine line: String, isUnclosed: Bool) -> String? {
        guard isUnclosed, let delimiter = FenceDelimiter.parse(line) else { return nil }
        return String(repeating: String(delimiter.marker), count: delimiter.count)
    }

    static func backtick(in text: NSString, selection: NSRange) -> TextEdit? {
        if selection.length > 0 {
            return WrapSelection.wrap(text, selection: selection, marker: "`")
        }
        let location = selection.location
        let next = location < text.length ? text.character(at: location) : 0x0A
        let previous = location > 0 ? text.character(at: location - 1) : 0x20
        if next == 0x60 {
            return TextEdit(range: NSRange(location: location, length: 0), replacement: "", selection: NSRange(location: location + 1, length: 0))
        }
        guard previous != 0x60, isBoundary(next), isBoundary(previous) || previous == 0x28 else { return nil }
        return TextEdit(range: NSRange(location: location, length: 0), replacement: "``", selection: NSRange(location: location + 1, length: 0))
    }

    private static func isBoundary(_ character: unichar) -> Bool {
        character == 0x20 || character == 0x0A || character == 0x09 || character == 0x29 || character == 0x2C || character == 0x2E
    }
}
