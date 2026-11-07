import Foundation

enum LinkTitle {
    static func short(for href: String) -> String? {
        guard let url = URL(string: href), ["http", "https"].contains(url.scheme?.lowercased()) else { return nil }
        let parts = url.path(percentEncoded: false).split(separator: "/").map(String.init)
        return ticket(parts, url: url) ?? gitLab(parts) ?? gitHub(parts) ?? page(parts) ?? design(parts)
    }

    private static func ticket(_ parts: [String], url: URL) -> String? {
        if let index = parts.firstIndex(of: "browse"), index + 1 < parts.count, isTicket(parts[index + 1]) {
            return parts[index + 1]
        }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return items.first { $0.name == "selectedIssue" }?.value.flatMap { isTicket($0) ? $0 : nil }
    }

    private static func gitLab(_ parts: [String]) -> String? {
        guard let dash = parts.firstIndex(of: "-"), dash > 0, dash + 2 < parts.count else { return nil }
        let project = parts[dash - 1]
        let id = parts[dash + 2]
        switch parts[dash + 1] {
        case "merge_requests" where isNumber(id): return "\(project) !\(id)"
        case "issues" where isNumber(id): return "\(project) #\(id)"
        case "commit": return "\(project)@\(id.prefix(7))"
        case "pipelines" where isNumber(id): return "\(project) pipeline \(id)"
        default: return nil
        }
    }

    private static func gitHub(_ parts: [String]) -> String? {
        guard parts.count >= 4, parts.contains("-") == false else { return nil }
        let repository = parts[1]
        let id = parts[3]
        switch parts[2] {
        case "pull", "issues": return isNumber(id) ? "\(repository) #\(id)" : nil
        case "commit": return "\(repository)@\(id.prefix(7))"
        default: return nil
        }
    }

    private static func page(_ parts: [String]) -> String? {
        guard let index = parts.firstIndex(of: "pages"), index + 2 < parts.count, isNumber(parts[index + 1]) else { return nil }
        return words(parts[index + 2], separators: "+")
    }

    private static func design(_ parts: [String]) -> String? {
        guard parts.count >= 3, ["design", "file", "board", "proto", "slides"].contains(parts[0]) else { return nil }
        return words(parts[2], separators: "-")
    }

    private static func words(_ slug: String, separators: String) -> String? {
        let text = slug.map { separators.contains($0) ? " " : String($0) }.joined().trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }

    private static func isTicket(_ value: String) -> Bool {
        value.range(of: "^[A-Z][A-Z0-9]+-[0-9]+$", options: .regularExpression) != nil
    }

    private static func isNumber(_ value: String) -> Bool {
        value.isEmpty == false && value.allSatisfy(\.isNumber)
    }
}
