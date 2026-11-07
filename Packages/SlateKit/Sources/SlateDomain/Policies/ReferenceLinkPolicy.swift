import Foundation

package enum ReferenceLinkPolicy {
    package static func ticketURL(_ key: String, base: String) -> URL? {
        let trimmed = base.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false else { return nil }
        if trimmed.contains("{key}") { return URL(string: trimmed.replacingOccurrences(of: "{key}", with: key)) }
        return URL(string: trimmed.hasSuffix("/") ? trimmed + key : trimmed + "/" + key)
    }

    package static func webAddress(remote: String) -> String? {
        var text = remote.trimmingCharacters(in: .whitespaces)
        guard text.isEmpty == false else { return nil }
        if let range = text.range(of: "://") { text = String(text[range.upperBound...]) }
        if let at = text.firstIndex(of: "@"), text[..<at].contains("/") == false { text = String(text[text.index(after: at)...]) }
        if let colon = text.firstIndex(of: ":"), let slash = text.firstIndex(of: "/"), colon < slash {
            let rest = text[text.index(after: colon)...]
            let host = text[..<colon]
            text = host + "/" + (rest.first?.isNumber == true ? String(rest.drop { $0 != "/" }.dropFirst()) : String(rest))
        }
        if text.hasSuffix(".git") { text.removeLast(4) }
        while text.hasSuffix("/") { text.removeLast() }
        guard text.contains("/") else { return nil }
        return "https://" + text
    }

    package static func mergeRequestURL(_ number: Int, remote: String) -> URL? {
        webAddress(remote: remote).flatMap { URL(string: $0 + "/-/merge_requests/\(number)") }
    }

    package static func commitURL(_ hash: String, remote: String) -> URL? {
        webAddress(remote: remote).flatMap { URL(string: $0 + "/commit/" + hash) }
    }
}
