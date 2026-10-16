import Foundation

enum PasteClassifier {
    static func classify(_ snapshot: PasteboardSnapshot) -> PasteKind {
        if snapshot.fileURLs.isEmpty == false {
            return .files(snapshot.fileURLs)
        }
        if let image = snapshot.image {
            return .image(image.data, fileExtension: image.fileExtension)
        }
        guard let string = snapshot.string, string.isEmpty == false else { return .nothing }
        if let url = singleURL(string) {
            return .url(url)
        }
        return .text(string, codeLanguage: codeLanguage(of: string))
    }

    static func singleURL(_ string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, trimmed.contains(where: \.isWhitespace) == false,
              let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              components.host?.isEmpty == false else { return nil }
        return trimmed
    }

    static func codeLanguage(of text: String) -> String? {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let filled = lines.filter { $0.trimmingCharacters(in: .whitespaces).isEmpty == false }
        guard filled.count >= 3 else { return nil }
        if looksLikeJSON(text) { return "json" }
        if looksLikeDiff(filled) { return "diff" }
        if looksLikeCrashOrLog(filled) { return "log" }
        guard looksLikeCode(filled) else { return nil }
        return language(of: text)
    }

    static func language(of text: String) -> String {
        if looksLikeJSON(text) { return "json" }
        let lines = text.split(separator: "\n").map(String.init)
        if looksLikeDiff(lines) { return "diff" }
        if looksLikeCrashOrLog(lines) { return "log" }
        if matches(text, #"@interface|@implementation|#import\s*[<"]|\[[A-Za-z_]\w*\s+[A-Za-z_]\w*[:\]]"#) { return "objc" }
        if matches(text, #"\b(func|let|var|guard|import|struct|extension|protocol)\s|->|@MainActor|@Observable"#) { return "swift" }
        if matches(text, #"^\s*(\$ |#!/|sudo |cd |export |echo |brew |git |xcodebuild |swift |make )"#, options: .anchorsMatchLines) { return "bash" }
        if matches(text, #"^\s*[A-Za-z0-9_.-]+:\s"#, options: .anchorsMatchLines), lines.allSatisfy({ $0.contains("{") == false }) { return "yaml" }
        return "plain"
    }

    private static func looksLikeJSON(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, first == "{" || first == "[", let data = trimmed.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) != nil
    }

    private static func looksLikeDiff(_ lines: [String]) -> Bool {
        lines.contains { $0.hasPrefix("@@ ") } || lines.contains { $0.hasPrefix("+++ ") } && lines.contains { $0.hasPrefix("--- ") }
    }

    private static func looksLikeCrashOrLog(_ lines: [String]) -> Bool {
        if lines.contains(where: { $0.contains("Thread 0 Crashed") || $0.hasPrefix("Exception Type:") }) { return true }
        let frames = lines.filter { matches($0, #"^\s*(at\s+\S|\d+\s+\S+\s+0x[0-9a-fA-F]+)"#) }.count
        if frames >= 2 { return true }
        let stamped = lines.filter { matches($0, #"^\s*\[?\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}|^\s*\[?\d{2}:\d{2}:\d{2}"#) }.count
        return stamped * 2 >= lines.count
    }

    private static func looksLikeCode(_ lines: [String]) -> Bool {
        let codeLike = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return line.hasPrefix("    ") || line.hasPrefix("\t")
                || trimmed.hasSuffix("{") || trimmed.hasSuffix("}") || trimmed.hasSuffix(";") || trimmed.hasSuffix(")")
                || trimmed.hasPrefix("//") || trimmed.hasPrefix("}")
        }.count
        let braces = lines.contains { $0.contains("{") || $0.contains("}") || $0.contains("();") }
        return braces && codeLike * 2 >= lines.count
    }

    private static func matches(_ text: String, _ pattern: String, options: NSRegularExpression.Options = []) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return false }
        return regex.firstMatch(in: text, range: NSRange(location: 0, length: (text as NSString).length)) != nil
    }

    static func fence(_ text: String, language: String) -> String {
        let body = text.hasSuffix("\n") ? String(text.dropLast()) : text
        let longest = body.components(separatedBy: "\n").map { line in line.prefix { $0 == "`" }.count }.max() ?? 0
        let ticks = String(repeating: "`", count: max(3, longest + 1))
        let label = language == "plain" ? "" : language
        return "\(ticks)\(label)\n\(body)\n\(ticks)"
    }
}
