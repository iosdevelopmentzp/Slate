import Foundation

package enum StemPolicy {
    package static let maxLength = 120
    package static let untitled = "Untitled"

    package static func stem(forTitle title: String) -> String {
        var text = title.trimmingCharacters(in: .whitespacesAndNewlines)
        text = text.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        text = String(String.UnicodeScalarView(text.unicodeScalars.filter(isKept)))
        text = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        text = trimmed(text)
        if text.count > maxLength {
            text = trimmed(String(text.prefix(maxLength)))
        }
        return text.isEmpty ? untitled : text
    }

    package static func unique(_ stem: String, among existing: [String]) -> String {
        let taken = Set(existing.map { $0.lowercased() })
        guard taken.contains(stem.lowercased()) else { return stem }
        var number = 2
        while taken.contains("\(stem) \(number)".lowercased()) {
            number += 1
        }
        return "\(stem) \(number)"
    }

    package static func isSame(_ lhs: String, _ rhs: String) -> Bool {
        lhs.lowercased() == rhs.lowercased()
    }

    private static let removed = Set("\\*?\"<>|".unicodeScalars)

    private static func isKept(_ scalar: Unicode.Scalar) -> Bool {
        if removed.contains(scalar) { return false }
        if CharacterSet.whitespacesAndNewlines.contains(scalar) { return true }
        return CharacterSet.controlCharacters.contains(scalar) == false
    }

    private static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet(charactersIn: " ."))
    }
}
