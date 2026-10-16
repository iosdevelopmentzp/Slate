import Foundation

enum FTSMatchBuilder {
    static func match(terms: [String], phrases: [String]) -> String {
        let words = terms.compactMap { term -> String? in
            guard hasText(term) else { return nil }
            return quote(term) + "*"
        }
        let quotedPhrases = phrases.compactMap { phrase -> String? in
            guard hasText(phrase) else { return nil }
            return quote(phrase)
        }
        return (words + quotedPhrases).joined(separator: " ")
    }

    static func quote(_ text: String) -> String {
        "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func hasText(_ text: String) -> Bool {
        text.unicodeScalars.contains { CharacterSet.alphanumerics.contains($0) }
    }
}
