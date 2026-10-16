import Foundation

package enum FrontmatterWriter {

    package static func write(_ header: NoteHeader, timeZone: TimeZone) -> String {
        var lines = [FrontmatterParser.delimiter]
        func add(_ key: String, _ value: String?) {
            guard let value else { return }
            lines.append("\(key): \(value)")
        }
        add("id", header.id.map { quoted($0.rawValue) })
        lines.append(header.title.map { "title: \(quoted($0))" } ?? "title:")
        add("type", header.type.map(quoted))
        add("created", header.created.map { date($0, timeZone: timeZone) })
        add("updated", header.updated.map { date($0, timeZone: timeZone) })
        add("tags", header.tags.map(list))
        add("pinned", header.pinned.map { $0 ? "true" : "false" })
        add("ticket", header.ticket.map(quoted))
        add("branch", header.branch.map(quoted))
        add("mr", header.mr.map(quoted))
        add("status", header.status.map(quoted))
        add("language", header.language.map(quoted))
        add("aliases", header.aliases.map(list))
        add("due", header.due.map(quoted))
        lines.append(contentsOf: header.unknownLines)
        lines.append(FrontmatterParser.delimiter)
        return lines.joined(separator: "\n") + "\n"
    }

    package static func date(_ date: Date, timeZone: TimeZone) -> String {
        date.formatted(Date.ISO8601FormatStyle(timeZoneSeparator: .colon, timeZone: timeZone))
    }

    package static func quoted(_ value: String) -> String {
        quoted(value, inList: false)
    }

    private static func quoted(_ raw: String, inList: Bool) -> String {
        let value = raw.replacingOccurrences(of: "\n", with: " ")
        guard needsQuotes(value, inList: inList) else { return value }
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private static let quotingStarts: Set<Character> = ["\"", "'", "[", "{", "#", "*", "&", "!", "|", ">", "%", "@", "`"]
    private static let reservedWords: Set<String> = ["true", "false", "null", "~"]

    private static func needsQuotes(_ value: String, inList: Bool) -> Bool {
        guard let first = value.first, let last = value.last else { return true }
        if quotingStarts.contains(first) { return true }
        if value.contains(": ") || value.contains(" #") { return true }
        if first.isWhitespace || last.isWhitespace { return true }
        if reservedWords.contains(value) { return true }
        if inList, value.contains(",") || value.contains("]") { return true }
        return false
    }

    private static func list(_ items: [String]) -> String {
        "[" + items.map { quoted($0, inList: true) }.joined(separator: ", ") + "]"
    }
}
