import Foundation

extension URL {
    func relativePath(inside root: URL) -> String? {
        let base = root.resolvingSymlinksInPath().path + "/"
        let path = resolvingSymlinksInPath().path
        guard isFileURL, path.hasPrefix(base) else { return nil }
        return String(path.dropFirst(base.count))
    }
}
