import Foundation

enum CheckboxToggle {
    static func toggled(_ line: String) -> String? {
        guard let item = MarkdownLineScanner.listItem(line), let box = item.checkbox else { return nil }
        return (line as NSString).replacingCharacters(in: NSRange(location: box.range.location + 1, length: 1), with: box.isChecked ? " " : "x")
    }

    static func cycled(_ line: String) -> String {
        let quote = ListEditing.quotePrefix(of: line)
        let rest = String(line.dropFirst(quote.count))
        let ns = rest as NSString
        guard let item = MarkdownLineScanner.listItem(rest) else {
            let indent = rest.prefix { $0 == " " || $0 == "\t" }
            let text = rest.dropFirst(indent.count)
            return quote + indent + "- [ ] " + text
        }
        let markerEnd = item.indent + item.markerLength
        guard let box = item.checkbox else {
            let after = markerEnd < ns.length ? ns.substring(from: markerEnd + 1) : ""
            return quote + ns.substring(to: markerEnd) + " [ ] " + after
        }
        if box.isChecked == false {
            return quote + ns.replacingCharacters(in: NSRange(location: box.range.location + 1, length: 1), with: "x")
        }
        let after = item.contentStart < ns.length ? ns.substring(from: item.contentStart) : ""
        return quote + ns.substring(to: markerEnd) + " " + after
    }
}
