import Foundation

package enum TodoLinePolicy {
    package struct Parsed: Hashable, Sendable {
        package let text: String
        package let isDone: Bool
    }

    package static func parse(_ line: String) -> Parsed? {
        guard line.contains("[") else { return nil }
        let ns = line as NSString
        guard let match = pattern.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)) else { return nil }
        let mark = ns.substring(with: match.range(at: 1))
        let text = match.range(at: 2).location == NSNotFound ? "" : ns.substring(with: match.range(at: 2))
        return Parsed(text: text.trimmingCharacters(in: .whitespaces), isDone: mark != " ")
    }

    package static func toggle(_ line: String) -> String? {
        let ns = line as NSString
        guard let match = pattern.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)) else { return nil }
        let markRange = match.range(at: 1)
        let mark = ns.substring(with: markRange)
        return ns.replacingCharacters(in: markRange, with: mark == " " ? "x" : " ")
    }

    private static let pattern = try! NSRegularExpression(pattern: #"^\s*(?:>\s*)*(?:[-*+]|\d{1,9}[.)])\s+\[([ xX])\](?:\s+(.*))?$"#)
}
