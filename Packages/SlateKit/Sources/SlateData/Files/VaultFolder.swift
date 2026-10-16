import Foundation
import SlateDomain

struct VaultFolder: Sendable {
    let root: URL

    func url(_ path: VaultPath) -> URL {
        root.appendingPathComponent(path.rawValue, isDirectory: false)
    }

    func url(folder: String) -> URL {
        folder.isEmpty ? root : root.appendingPathComponent(folder, isDirectory: true)
    }

    func meta(at url: URL, path: VaultPath) throws -> FileMeta {
        let values = try url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey, .fileSizeKey])
        let modified = values.contentModificationDate ?? .distantPast
        return FileMeta(path: path, created: values.creationDate ?? modified, modified: modified, size: values.fileSize ?? 0)
    }

    func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    func spaceFolders() throws -> [SpaceName] {
        guard exists(root) else { return [] }
        let items = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        return items
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .map(\.lastPathComponent)
            .filter { $0.hasPrefix("_") == false && $0.hasPrefix(".") == false }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .map(SpaceName.init(rawValue:))
    }

    func relativePath(of url: URL, under base: URL) -> String? {
        let baseComponents = base.standardizedFileURL.pathComponents
        let components = url.standardizedFileURL.pathComponents
        guard components.count > baseComponents.count, Array(components.prefix(baseComponents.count)) == baseComponents else { return nil }
        return components.dropFirst(baseComponents.count).joined(separator: "/")
    }
}
