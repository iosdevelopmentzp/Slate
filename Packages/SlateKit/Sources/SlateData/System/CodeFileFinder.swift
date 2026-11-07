import Foundation

enum CodeFileFinder {
    static let skipped: Set<String> = [".git", ".build", "build", "DerivedData", "Pods", "Carthage", "node_modules", ".swiftpm"]
    static let limit = 200_000

    static func find(_ path: String, in roots: [URL]) -> URL? {
        let manager = FileManager.default
        if path.hasPrefix("/") {
            return manager.fileExists(atPath: path) ? URL(fileURLWithPath: path) : nil
        }
        for root in roots {
            let direct = root.appendingPathComponent(path)
            if manager.fileExists(atPath: direct.path) { return direct }
        }
        let suffix = "/" + path
        for root in roots {
            if let found = search(suffix, in: root) { return found }
        }
        return nil
    }

    private static func search(_ suffix: String, in root: URL) -> URL? {
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return nil }
        var best: URL?
        var visited = 0
        for case let url as URL in enumerator {
            visited += 1
            if visited > limit { break }
            if skipped.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }
            guard url.path.hasSuffix(suffix) else { continue }
            if best == nil || url.path.count < best?.path.count ?? 0 { best = url }
        }
        return best
    }
}
