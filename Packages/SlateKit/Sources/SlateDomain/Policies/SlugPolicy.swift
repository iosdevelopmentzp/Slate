import Foundation

package enum SlugPolicy {
    package static let maxLength = 48

    package static func slug(_ title: String) -> String {
        let folded = title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX")).lowercased()
        var result = ""
        var lastWasDash = false
        for scalar in folded.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar), scalar.isASCII {
                result.unicodeScalars.append(scalar)
                lastWasDash = false
            } else if lastWasDash == false, result.isEmpty == false {
                result.append("-")
                lastWasDash = true
            }
        }
        var cut = String(result.prefix(maxLength))
        while cut.hasSuffix("-") { cut.removeLast() }
        return cut
    }

    package static func renderBranch(pattern: String?, ticket: String?, title: String) -> String? {
        guard let pattern, pattern.isEmpty == false else { return nil }
        if pattern.contains("{{ticket}}"), (ticket ?? "").isEmpty { return nil }
        let rendered = pattern
            .replacingOccurrences(of: "{{ticket}}", with: ticket ?? "")
            .replacingOccurrences(of: "{{slug}}", with: slug(title))
        var cleaned = rendered
        while cleaned.contains("--") { cleaned = cleaned.replacingOccurrences(of: "--", with: "-") }
        while cleaned.hasSuffix("-") || cleaned.hasSuffix("/") { cleaned.removeLast() }
        return cleaned.isEmpty ? nil : cleaned
    }
}
