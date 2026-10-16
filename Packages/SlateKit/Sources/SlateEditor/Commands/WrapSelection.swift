import Foundation

enum WrapSelection {
    static func wrap(_ text: NSString, selection: NSRange, marker: String) -> TextEdit {
        let length = (marker as NSString).length
        if selection.location >= length, selection.upperBound + length <= text.length,
           text.substring(with: NSRange(location: selection.location - length, length: length)) == marker,
           text.substring(with: NSRange(location: selection.upperBound, length: length)) == marker {
            let outer = NSRange(location: selection.location - length, length: selection.length + length * 2)
            return TextEdit(range: outer, replacement: text.substring(with: selection), selection: NSRange(location: outer.location, length: selection.length))
        }
        let selected = text.substring(with: selection)
        if selected.hasPrefix(marker), selected.hasSuffix(marker), selection.length >= length * 2 {
            let inner = (selected as NSString).substring(with: NSRange(location: length, length: selection.length - length * 2))
            return TextEdit(range: selection, replacement: inner, selection: NSRange(location: selection.location, length: (inner as NSString).length))
        }
        return TextEdit(range: selection, replacement: marker + selected + marker, selection: NSRange(location: selection.location + length, length: selection.length))
    }
}
