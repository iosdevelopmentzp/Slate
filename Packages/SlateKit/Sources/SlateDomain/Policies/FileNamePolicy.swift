import Foundation

package enum FileNamePolicy {
    package static func cleaned(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        guard trimmed.isEmpty == false, trimmed.hasPrefix(".") == false else { return nil }
        return trimmed
    }

    package static func renamed(_ name: String, keeping original: String) -> String? {
        guard let cleaned = cleaned(name) else { return nil }
        let ext = (original as NSString).pathExtension
        guard ext.isEmpty == false, (cleaned as NSString).pathExtension.isEmpty else { return cleaned }
        return "\(cleaned).\(ext)"
    }

    package static func unique(_ name: String, among taken: [String]) -> String {
        let used = Set(taken.map { $0.lowercased() })
        guard used.contains(name.lowercased()) else { return name }
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var number = 2
        while true {
            let candidate = ext.isEmpty ? "\(base) \(number)" : "\(base) \(number).\(ext)"
            if used.contains(candidate.lowercased()) == false { return candidate }
            number += 1
        }
    }
}
