import Foundation

package enum TitlePolicy {
    package struct Split: Hashable, Sendable {
        package let ticket: String?
        package let title: String
    }

    package static func title(fromBody body: String) -> String? {
        for line in body.split(separator: "\n") {
            let text = PreviewPolicy.plainText(of: line.trimmingCharacters(in: .whitespaces))
            guard text.isEmpty == false else { continue }
            return String(text.prefix(StemPolicy.maxLength)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    package static func split(_ text: String, ticketPattern: String) -> Split {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let regex = try? NSRegularExpression(pattern: "^\\s*(?:" + ticketPattern + ")"),
              let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: (trimmed as NSString).length)) else {
            return Split(ticket: nil, title: trimmed)
        }
        let ns = trimmed as NSString
        let group = match.numberOfRanges > 1 && match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range
        let ticket = ns.substring(with: group)
        var rest = ns.substring(from: match.range.upperBound)
        rest = rest.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ":-–—")))
        return Split(ticket: ticket, title: rest)
    }

    package static func startsWithTicket(_ text: String, ticketPattern: String) -> Bool {
        split(text, ticketPattern: ticketPattern).ticket != nil
    }

    package static func render(_ pattern: String?, ticket: String?, title: String) -> String {
        guard let pattern, let ticket, ticket.isEmpty == false else { return title }
        let rendered = pattern
            .replacingOccurrences(of: "{{ticket}}", with: ticket)
            .replacingOccurrences(of: "{{title}}", with: title)
        return rendered.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
