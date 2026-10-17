import Foundation
import SlateDomain

actor FileVaultStore: VaultFileStore {
    private let folder: VaultFolder
    private let ownWrites: OwnWrites
    private let recycle: @Sendable (URL) throws -> Void

    init(root: URL, ownWrites: OwnWrites, recycle: @escaping @Sendable (URL) throws -> Void = { try FileManager.default.trashItem(at: $0, resultingItemURL: nil) }) {
        folder = VaultFolder(root: root)
        self.ownWrites = ownWrites
        self.recycle = recycle
    }

    func enumerate() throws -> [FileMeta] {
        var metas: [FileMeta] = []
        let keys: [URLResourceKey] = [.isRegularFileKey, .creationDateKey, .contentModificationDateKey, .fileSizeKey]
        for space in try folder.spaceFolders() {
            let base = folder.url(folder: space.rawValue)
            guard let enumerator = FileManager.default.enumerator(at: base, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            for case let url as URL in enumerator {
                guard url.pathExtension == VaultPath.noteExtension,
                      (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true,
                      let relative = folder.relativePath(of: url, under: base)
                else { continue }
                let path = VaultPath(rawValue: "\(space.rawValue)/\(relative)")
                if let meta = try? folder.meta(at: url, path: path) {
                    metas.append(meta)
                }
            }
        }
        return metas
    }

    nonisolated func read(_ path: VaultPath) throws -> FileContents {
        let url = folder.url(path)
        guard folder.exists(url) else { throw VaultError.notFound(path) }
        let data = try FileCoordination.readCoordinated(url)
        return FileContents(data: data, hash: .of(data), meta: try folder.meta(at: url, path: path))
    }

    func meta(_ path: VaultPath) throws -> FileMeta? {
        let url = folder.url(path)
        guard folder.exists(url) else { return nil }
        return try folder.meta(at: url, path: path)
    }

    func write(_ path: VaultPath, data: Data, expected: ContentHash?) throws -> WriteResult {
        let url = folder.url(path)
        let hash = ContentHash.of(data)
        let result: WriteResult = try FileCoordination.writing(url) { actual in
            if let expected {
                let disk = (try? Data(contentsOf: actual)).map(ContentHash.of)
                guard disk == expected else { return .conflict(diskHash: disk) }
            }
            try FileCoordination.replace(actual, with: data)
            return .written(hash)
        }
        if case .written = result {
            ownWrites.record(path, hash: hash)
        }
        return result
    }

    func create(_ path: VaultPath, data: Data) throws -> ContentHash {
        let url = folder.url(path)
        let hash = ContentHash.of(data)
        try FileCoordination.writing(url) { actual in
            guard folder.exists(actual) == false else { throw VaultError.alreadyExists(path.rawValue) }
            try FileCoordination.replace(actual, with: data)
        }
        ownWrites.record(path, hash: hash)
        return hash
    }

    func move(from source: VaultPath, to target: VaultPath) throws {
        let from = folder.url(source)
        let to = folder.url(target)
        guard folder.exists(from) else { throw VaultError.notFound(source) }
        guard folder.exists(to) == false else { throw VaultError.alreadyExists(target.rawValue) }
        try FileManager.default.createDirectory(at: to.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileCoordination.moving(from: from, to: to)
        ownWrites.record(source, hash: nil)
        ownWrites.record(target, hash: (try? Data(contentsOf: to)).map(ContentHash.of))
    }

    func fileNames(inFolder name: String) throws -> [String] {
        let url = folder.url(folder: name)
        guard folder.exists(url) else { return [] }
        return try FileManager.default.contentsOfDirectory(atPath: url.path).filter { $0.hasPrefix(".") == false }
    }

    func folders() throws -> [FolderPath] {
        var found: [FolderPath] = []
        let keys: [URLResourceKey] = [.isDirectoryKey]
        for space in try folder.spaceFolders() {
            let base = folder.url(folder: space.rawValue)
            guard let enumerator = FileManager.default.enumerator(at: base, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            for case let url as URL in enumerator {
                guard (try? url.resourceValues(forKeys: Set(keys)).isDirectory) == true else { continue }
                guard url.lastPathComponent.hasPrefix("_") == false else {
                    enumerator.skipDescendants()
                    continue
                }
                guard let relative = folder.relativePath(of: url, under: base) else { continue }
                found.append(FolderPath(rawValue: "\(space.rawValue)/\(relative)"))
            }
        }
        return found.sorted { $0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending }
    }

    func createFolder(_ target: FolderPath) throws {
        let url = folder.url(folder: target.rawValue)
        guard folder.exists(url) == false else { throw VaultError.alreadyExists(target.name) }
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func moveFolder(from source: FolderPath, to target: FolderPath) throws {
        let from = folder.url(folder: source.rawValue)
        let to = folder.url(folder: target.rawValue)
        guard folder.exists(from) else { throw VaultError.notFound(VaultPath(rawValue: source.rawValue)) }
        if StemPolicy.isSame(source.rawValue, target.rawValue) {
            let step = from.deletingLastPathComponent().appendingPathComponent(".\(source.name).slate-rename", isDirectory: true)
            try FileCoordination.moving(from: from, to: step)
            try FileCoordination.moving(from: step, to: to)
            return
        }
        guard folder.exists(to) == false else { throw VaultError.alreadyExists(target.name) }
        try FileCoordination.moving(from: from, to: to)
    }

    func removeFolder(_ target: FolderPath) throws {
        let url = folder.url(folder: target.rawValue)
        guard folder.exists(url) else { return }
        if Self.holdsVisibleFiles(url) {
            try recycle(url)
        } else {
            try FileManager.default.removeItem(at: url)
        }
    }

    private static func holdsVisibleFiles(_ url: URL) -> Bool {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else { return false }
        for case let item as URL in enumerator where (try? item.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
            return true
        }
        return false
    }
}
