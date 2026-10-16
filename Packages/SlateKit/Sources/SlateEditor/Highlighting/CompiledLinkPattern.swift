import Foundation

struct CompiledLinkPattern {
    let id: String
    let regex: NSRegularExpression

    static func compile(_ patterns: [EditorLinkPattern]) -> [CompiledLinkPattern] {
        patterns.compactMap { pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern.regex) else { return nil }
            return CompiledLinkPattern(id: pattern.id, regex: regex)
        }
    }
}
