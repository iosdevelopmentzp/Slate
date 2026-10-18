import Foundation

package enum ProjectLookupPolicy {
    package static func project(for directory: String, repository: RepositoryInfo?, among spaces: [Space]) -> Space? {
        let projects = spaces.filter(\.isProject)
        let paths = [directory, repository?.root, repository?.mainRoot].compactMap { $0 }.map(standardized)
        if let byPath = projects.first(where: { space in
            (space.project?.repositories ?? []).map(standardized).contains { repository in
                paths.contains { $0 == repository || $0.hasPrefix(repository + "/") }
            }
        }) {
            return byPath
        }
        guard let remote = repository?.remote.flatMap(normalizedRemote) else { return nil }
        return projects.first { $0.project?.remote.flatMap(normalizedRemote) == remote }
    }

    package static func normalizedRemote(_ remote: String) -> String? {
        var text = remote.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard text.isEmpty == false else { return nil }
        for scheme in ["https://", "http://", "ssh://", "git://"] where text.hasPrefix(scheme) {
            text = String(text.dropFirst(scheme.count))
        }
        if let at = text.firstIndex(of: "@"), text[..<at].contains("/") == false {
            text = String(text[text.index(after: at)...])
        }
        if let colon = text.firstIndex(of: ":"), text[..<colon].contains("/") == false {
            let rest = text[text.index(after: colon)...]
            let path = rest.drop { $0.isNumber }
            text = String(text[..<colon]) + "/" + (path.hasPrefix("/") ? String(path.dropFirst()) : String(path))
        }
        while text.hasSuffix("/") { text = String(text.dropLast()) }
        if text.hasSuffix(".git") { text = String(text.dropLast(4)) }
        return text
    }

    private static func standardized(_ path: String) -> String {
        let expanded = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded).standardizedFileURL.resolvingSymlinksInPath()
        let text = url.path
        return text.count > 1 && text.hasSuffix("/") ? String(text.dropLast()) : text
    }
}
