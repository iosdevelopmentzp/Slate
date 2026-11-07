import Foundation

enum WikiQuery {
    struct Open: Equatable {
        let start: Int
        let query: String
    }

    struct Closed: Equatable {
        let range: NSRange
        let target: String
        let label: String
    }

    static let longestQuery = 80

    static func open(before text: String) -> Open? {
        let string = text as NSString
        let open = string.range(of: "[[", options: .backwards)
        guard open.location != NSNotFound else { return nil }
        let query = string.substring(from: NSMaxRange(open))
        guard query.count <= longestQuery, query.contains(where: { "[]".contains($0) || $0.isNewline || $0 == RichText.lineBreak }) == false else { return nil }
        return Open(start: open.location, query: query)
    }

    static func closed(before text: String) -> Closed? {
        let string = text as NSString
        guard string.hasSuffix("]]") else { return nil }
        let body = string.substring(to: string.length - 2)
        guard let open = open(before: body) else { return nil }
        let parts = open.query.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        let target = parts[0].trimmingCharacters(in: .whitespaces)
        guard target.isEmpty == false else { return nil }
        let label = parts.count > 1 && parts[1].isEmpty == false ? parts[1] : target
        return Closed(range: NSRange(location: open.start, length: string.length - open.start), target: target, label: label)
    }
}
