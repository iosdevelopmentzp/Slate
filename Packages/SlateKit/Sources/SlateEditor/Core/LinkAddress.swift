import Foundation

enum LinkAddress {
    static func href(for input: String, notes: [String]) -> String? {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("[["), value.hasSuffix("]]") {
            value = String(value.dropFirst(2).dropLast(2)).trimmingCharacters(in: .whitespaces)
        }
        guard value.isEmpty == false else { return nil }
        if let note = notes.first(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) {
            return RichText.wikiPrefix + note
        }
        if hasScheme(value) || value.looksLikeURL || isPath(value) {
            return value
        }
        if looksLikeDomain(value) {
            return "https://" + value
        }
        let name = value.filter { "[]|".contains($0) == false }.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : RichText.wikiPrefix + name
    }

    static func editableText(_ text: String) -> String? {
        text.contains { $0.isNewline || $0 == "\u{FFFC}" || $0 == RichText.lineBreak } ? nil : text
    }

    static func display(_ href: String) -> String {
        isNote(href) ? String(href.dropFirst(RichText.wikiPrefix.count)) : href
    }

    static func isNote(_ href: String) -> Bool {
        href.hasPrefix(RichText.wikiPrefix)
    }

    static func copyText(_ href: String) -> String {
        isNote(href) ? "[[\(display(href))]]" : href
    }

    private static func hasScheme(_ value: String) -> Bool {
        value.range(of: "^[A-Za-z][A-Za-z0-9+.-]*://", options: .regularExpression) != nil
            || value.lowercased().hasPrefix("mailto:")
    }

    private static func isPath(_ value: String) -> Bool {
        ["/", "~/", "./", "../"].contains { value.hasPrefix($0) }
    }

    private static func looksLikeDomain(_ value: String) -> Bool {
        guard value.contains(" ") == false, let host = value.split(separator: "/", maxSplits: 1).first, host.contains(".") else { return false }
        let ending = host.split(separator: ".").last ?? ""
        return ending.count >= 2 && ending.allSatisfy(\.isLetter)
    }
}
