import Foundation

struct CompletionContext: Equatable {
    let kind: EditorCompletionKind
    let range: NSRange

    static func at(_ caret: Int, in text: NSString) -> CompletionContext? {
        guard caret <= text.length else { return nil }
        let lineStart = text.lineRange(for: NSRange(location: caret, length: 0)).location
        let before = text.substring(with: NSRange(location: lineStart, length: caret - lineStart)) as NSString
        let open = before.range(of: "[[", options: .backwards)
        if open.location != NSNotFound {
            let inner = before.substring(from: open.upperBound)
            if inner.contains("]]") == false, inner.contains("|") == false, inner.contains("[") == false {
                return CompletionContext(kind: .note, range: NSRange(location: lineStart + open.upperBound, length: (inner as NSString).length))
            }
        }
        var start = before.length
        while start > 0, isTagCharacter(before.character(at: start - 1)) {
            start -= 1
        }
        guard start > 0, before.character(at: start - 1) == 0x23 else { return nil }
        let hash = start - 1
        if hash > 0 {
            let previous = before.character(at: hash - 1)
            guard previous == 0x20 || previous == 0x09 || previous == 0x28 else { return nil }
        }
        guard start < before.length || hash > 0 else { return nil }
        return CompletionContext(kind: .tag, range: NSRange(location: lineStart + start, length: before.length - start))
    }

    private static func isTagCharacter(_ character: unichar) -> Bool {
        (0x61...0x7A).contains(character) || (0x30...0x39).contains(character) || character == 0x5F || character == 0x2F || character == 0x2D
    }
}
