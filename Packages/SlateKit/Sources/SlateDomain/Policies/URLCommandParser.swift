import Foundation

package enum URLCommandParser {
    package static let scheme = "slate"
    package static let maxLength = 100_000

    package static func parse(_ url: URL) -> URLCommand? {
        guard url.scheme?.lowercased() == scheme, url.absoluteString.count <= maxLength,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let route = (components.host ?? components.path).lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var query: [String: String] = [:]
        for item in components.queryItems ?? [] {
            guard let value = item.value, query[item.name] == nil else { continue }
            query[item.name] = value
        }
        switch route {
        case "new":
            let draft = NoteDraft(
                title: nonEmpty(query["title"]),
                type: nonEmpty(query["type"])?.lowercased(),
                space: nonEmpty(query["space"]).flatMap(spaceName),
                ticket: nonEmpty(query["ticket"]),
                body: nonEmpty(query["body"]).map { $0.hasSuffix("\n") ? $0 : $0 + "\n" }
            )
            return .new(draft)
        case "open":
            if let ticket = nonEmpty(query["ticket"]) { return .open(.ticket(ticket)) }
            if let id = nonEmpty(query["id"]) { return .open(.id(NoteID(rawValue: id))) }
            if let title = nonEmpty(query["title"]) { return .open(.title(title)) }
            return nil
        case "append":
            guard let text = nonEmpty(query["text"]) else { return nil }
            let section = nonEmpty(query["section"])
            if query["today"] == "1" || query["today"] == "true" { return .append(text: text, target: .today, section: section) }
            if let ticket = nonEmpty(query["ticket"]) { return .append(text: text, target: .ticket(ticket), section: section) }
            if let id = nonEmpty(query["id"]) { return .append(text: text, target: .id(NoteID(rawValue: id)), section: section) }
            return nil
        case "capture":
            return .capture
        case "search":
            return .search(query["q"] ?? "")
        default:
            return nil
        }
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return nil }
        return value
    }

    private static func spaceName(_ value: String) -> SpaceName? {
        guard value.contains("/") == false, value.hasPrefix(".") == false, value.hasPrefix("_") == false else { return nil }
        return SpaceName(rawValue: value)
    }
}
