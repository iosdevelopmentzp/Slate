import Foundation
import SlateDomain

package final class SpyVaultFileStore: VaultFileStore, @unchecked Sendable {
    package enum Call: Hashable {
        case enumerate
        case read(VaultPath)
        case write(VaultPath, expected: ContentHash?)
        case create(VaultPath)
        case move(from: VaultPath, to: VaultPath)
        case createFolder(SpaceName)
        case moveFolder(from: SpaceName, to: SpaceName)
        case removeFolder(SpaceName)
    }

    private struct File {
        var data: Data
        var meta: FileMeta
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var files: [VaultPath: File] = [:]
    private var folders: Set<SpaceName> = []
    private var _writeError: TestError?
    private var _modified = Date(timeIntervalSince1970: 1_800_000_000)

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var writeError: TestError? {
        get { lock.withLock { _writeError } }
        set { lock.withLock { _writeError = newValue } }
    }

    package var paths: Set<VaultPath> {
        lock.withLock { Set(files.keys) }
    }

    package var folderNames: Set<SpaceName> {
        lock.withLock { folders }
    }

    @discardableResult
    package func seed(_ path: VaultPath, _ text: String, created: Date? = nil) -> ContentHash {
        lock.withLock {
            let data = Data(text.utf8)
            _modified = _modified.addingTimeInterval(1)
            files[path] = File(data: data, meta: FileMeta(path: path, created: created ?? _modified, modified: _modified, size: data.count))
            return .of(data)
        }
    }

    package func text(at path: VaultPath) -> String? {
        lock.withLock { files[path].map { String(decoding: $0.data, as: UTF8.self) } }
    }

    package func enumerate() async throws -> [FileMeta] {
        lock.withLock {
            _calls.append(.enumerate)
            return files.values.map(\.meta).filter { $0.path.isNote }
        }
    }

    package func read(_ path: VaultPath) async throws -> FileContents {
        try lock.withLock {
            _calls.append(.read(path))
            guard let file = files[path] else { throw VaultError.notFound(path) }
            return FileContents(data: file.data, hash: .of(file.data), meta: file.meta)
        }
    }

    package func meta(_ path: VaultPath) async throws -> FileMeta? {
        lock.withLock { files[path]?.meta }
    }

    package func write(_ path: VaultPath, data: Data, expected: ContentHash?) async throws -> WriteResult {
        try lock.withLock {
            _calls.append(.write(path, expected: expected))
            if let _writeError { throw _writeError }
            let disk = files[path].map { ContentHash.of($0.data) }
            if let expected, disk != expected {
                return .conflict(diskHash: disk)
            }
            store(path, data)
            return .written(.of(data))
        }
    }

    package func create(_ path: VaultPath, data: Data) async throws -> ContentHash {
        try lock.withLock {
            _calls.append(.create(path))
            if let _writeError { throw _writeError }
            guard files[path] == nil else { throw VaultError.alreadyExists(path.rawValue) }
            store(path, data)
            return .of(data)
        }
    }

    package func move(from source: VaultPath, to target: VaultPath) async throws {
        try lock.withLock {
            _calls.append(.move(from: source, to: target))
            guard let file = files.removeValue(forKey: source) else { throw VaultError.notFound(source) }
            guard files[target] == nil else { throw VaultError.alreadyExists(target.rawValue) }
            files[target] = File(data: file.data, meta: FileMeta(path: target, created: file.meta.created, modified: file.meta.modified, size: file.meta.size))
        }
    }

    package func fileNames(inFolder folder: String) async throws -> [String] {
        lock.withLock { files.keys.filter { $0.folder == folder }.map(\.fileName) }
    }

    package func createFolder(_ name: SpaceName) async throws {
        try lock.withLock {
            _calls.append(.createFolder(name))
            guard folders.contains(name) == false else { throw VaultError.alreadyExists(name.rawValue) }
            folders.insert(name)
        }
    }

    package func removeFolder(_ name: SpaceName) async throws {
        lock.withLock {
            _calls.append(.removeFolder(name))
            folders.remove(name)
            for path in files.keys where path.space == name {
                files[path] = nil
            }
        }
    }

    package func moveFolder(from source: SpaceName, to target: SpaceName) async throws {
        lock.withLock {
            _calls.append(.moveFolder(from: source, to: target))
            folders.remove(source)
            folders.insert(target)
            for (path, file) in files where path.space == source {
                files[path] = nil
                let moved = VaultPath(rawValue: ([target.rawValue] + path.components.dropFirst()).joined(separator: "/"))
                files[moved] = File(data: file.data, meta: FileMeta(path: moved, created: file.meta.created, modified: file.meta.modified, size: file.meta.size))
            }
        }
    }

    private func store(_ path: VaultPath, _ data: Data) {
        _modified = _modified.addingTimeInterval(1)
        let created = files[path]?.meta.created ?? _modified
        files[path] = File(data: data, meta: FileMeta(path: path, created: created, modified: _modified, size: data.count))
    }
}
