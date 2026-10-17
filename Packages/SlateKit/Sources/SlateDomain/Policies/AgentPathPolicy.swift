import Foundation

package enum AgentPathPolicy {
    package static func trimmed(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    package static func isProtected(_ components: [String]) -> Bool {
        components.contains { $0.hasPrefix(".") || $0.hasPrefix("_") }
    }

    package static func notePath(from raw: String, root: URL) throws -> VaultPath {
        guard let relative = relative(raw, root: root) else { throw AgentError.outsideNotes(raw) }
        let components = relative.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard components.count > 1,
              components.allSatisfy({ $0.isEmpty == false && $0 != ".." && $0 != "." }),
              isProtected(components) == false,
              relative.hasSuffix(".\(VaultPath.noteExtension)")
        else { throw AgentError.outsideNotes(raw) }
        return VaultPath(rawValue: relative)
    }

    package static func folder(from raw: String) throws -> FolderPath {
        let relative = trimmed(raw)
        let components = relative.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard relative.isEmpty == false,
              components.allSatisfy({ $0.isEmpty == false && $0 != ".." && $0 != "." }),
              isProtected(components) == false
        else { throw AgentError.badFolder(raw) }
        return FolderPath(rawValue: relative)
    }

    private static func relative(_ raw: String, root: URL) -> String? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.hasPrefix("/") || text.hasPrefix("~") else { return text }
        let absolute = URL(fileURLWithPath: (text as NSString).expandingTildeInPath).standardizedFileURL.path
        let base = root.standardizedFileURL.path
        guard absolute.hasPrefix(base + "/") else { return nil }
        return String(absolute.dropFirst(base.count + 1))
    }
}
