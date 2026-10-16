import Foundation
import SlateDomain

actor FileTrashRepository: TrashRepository {
    static let folderName = ".trash"
    static let orphanSpace = SpaceName(rawValue: "Inbox")

    private let folder: VaultFolder
    private let trashRoot: URL
    private let manifestURL: URL
    private let recycle: @Sendable (URL) throws -> Void

    init(root: URL, recycle: @escaping @Sendable (URL) throws -> Void = { try FileManager.default.trashItem(at: $0, resultingItemURL: nil) }) {
        self.recycle = recycle
        folder = VaultFolder(root: root)
        trashRoot = root.appendingPathComponent(Self.folderName, isDirectory: true)
        manifestURL = trashRoot.appendingPathComponent("manifest.json")
    }

    func trash(_ path: VaultPath, at date: Date) throws -> TrashItem {
        let source = folder.url(path)
        guard folder.exists(source) else { throw VaultError.notFound(path) }
        let target = uniquePath(for: path, existing: { folder.exists(trashURL($0)) })
        let targetURL = trashURL(target)
        try FileManager.default.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileCoordination.moving(from: source, to: targetURL)
        let item = TrashItem(path: target, originalPath: path, trashedAt: date)
        var entries = try manifestEntries()
        entries.append(item)
        try save(entries)
        return item
    }

    func restore(_ item: TrashItem) throws -> VaultPath {
        let source = trashURL(item.path)
        guard folder.exists(source) else { throw VaultError.notFound(item.path) }
        let target = uniquePath(for: item.originalPath, existing: { folder.exists(folder.url($0)) })
        let targetURL = folder.url(target)
        try FileManager.default.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileCoordination.moving(from: source, to: targetURL)
        try save(try manifestEntries().filter { $0.path != item.path })
        return target
    }

    func items() throws -> [TrashItem] {
        let entries = try manifestEntries().filter { folder.exists(trashURL($0.path)) }
        let known = Set(entries.map(\.path))
        let orphans = try orphanFiles().filter { known.contains($0.path) == false }
        return (entries + orphans).sorted { $0.trashedAt > $1.trashedAt }
    }

    func delete(_ item: TrashItem) throws {
        let url = trashURL(item.path)
        if folder.exists(url) {
            try recycle(url)
        }
        try save(try manifestEntries().filter { $0.path != item.path })
    }

    private func trashURL(_ path: VaultPath) -> URL {
        trashRoot.appendingPathComponent(path.rawValue, isDirectory: false)
    }

    private func uniquePath(for path: VaultPath, existing: (VaultPath) -> Bool) -> VaultPath {
        guard existing(path) else { return path }
        var number = 2
        while existing(path.replacingStem(with: "\(path.stem) \(number)")) {
            number += 1
        }
        return path.replacingStem(with: "\(path.stem) \(number)")
    }

    private func orphanFiles() throws -> [TrashItem] {
        guard folder.exists(trashRoot), let enumerator = FileManager.default.enumerator(at: trashRoot, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else { return [] }
        var items: [TrashItem] = []
        for case let url as URL in enumerator where url.pathExtension == VaultPath.noteExtension {
            guard let relative = folder.relativePath(of: url, under: trashRoot), relative.hasPrefix("_attachments/") == false else { continue }
            let path = VaultPath(rawValue: relative)
            let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let original = path.space == nil ? VaultPath(space: Self.orphanSpace, stem: path.stem) : path
            items.append(TrashItem(path: path, originalPath: original, trashedAt: modified))
        }
        return items
    }

    private func manifestEntries() throws -> [TrashItem] {
        guard let object = try JSONFile.object(at: manifestURL), let items = object["items"] as? [[String: Any]] else { return [] }
        return items.compactMap { entry in
            guard let path = entry["path"] as? String,
                  let original = entry["originalPath"] as? String,
                  let date = (entry["trashedAt"] as? String).flatMap({ try? Date($0, strategy: .iso8601) })
            else { return nil }
            return TrashItem(path: VaultPath(rawValue: path), originalPath: VaultPath(rawValue: original), trashedAt: date)
        }
    }

    private func save(_ entries: [TrashItem]) throws {
        let items: [[String: Any]] = entries.map { item in
            [
                "path": item.path.rawValue,
                "originalPath": item.originalPath.rawValue,
                "trashedAt": FrontmatterWriter.date(item.trashedAt, timeZone: .current),
            ]
        }
        try JSONFile.write(["version": 1, "items": items], to: manifestURL)
    }
}
