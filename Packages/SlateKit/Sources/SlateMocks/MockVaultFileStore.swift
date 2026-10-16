import Foundation
import SlateDomain

actor MockVaultFileStore: VaultFileStore {
    private var files: [VaultPath: (data: Data, meta: FileMeta)] = [:]
    private var folders: Set<SpaceName>

    init(documents: [NoteDocument] = MockVault.documents, spaces: [Space] = MockVault.spaces) {
        folders = Set(spaces.map(\.folder))
        for document in documents {
            let data = NoteCodec.encode(header: document.header, body: document.body, opaqueHeader: nil, timeZone: .gmt)
            files[document.path] = (data, document.meta)
        }
    }

    func enumerate() -> [FileMeta] {
        files.values.map(\.meta)
    }

    func read(_ path: VaultPath) throws -> FileContents {
        guard let file = files[path] else { throw VaultError.notFound(path) }
        return FileContents(data: file.data, hash: .of(file.data), meta: file.meta)
    }

    func meta(_ path: VaultPath) -> FileMeta? {
        files[path]?.meta
    }

    func write(_ path: VaultPath, data: Data, expected: ContentHash?) -> WriteResult {
        let disk = files[path].map { ContentHash.of($0.data) }
        if let expected, disk != expected {
            return .conflict(diskHash: disk)
        }
        store(path, data)
        return .written(.of(data))
    }

    func create(_ path: VaultPath, data: Data) throws -> ContentHash {
        guard files[path] == nil else { throw VaultError.alreadyExists(path.rawValue) }
        store(path, data)
        return .of(data)
    }

    func move(from source: VaultPath, to target: VaultPath) throws {
        guard let file = files.removeValue(forKey: source) else { throw VaultError.notFound(source) }
        files[target] = (file.data, FileMeta(path: target, created: file.meta.created, modified: file.meta.modified, size: file.meta.size))
    }

    func fileNames(inFolder folder: String) -> [String] {
        files.keys.filter { $0.folder == folder }.map(\.fileName)
    }

    func createFolder(_ name: SpaceName) {
        folders.insert(name)
    }

    func removeFolder(_ name: SpaceName) {
        folders.remove(name)
    }

    func moveFolder(from source: SpaceName, to target: SpaceName) {
        folders.remove(source)
        folders.insert(target)
    }

    private func store(_ path: VaultPath, _ data: Data) {
        let created = files[path]?.meta.created ?? .now
        files[path] = (data, FileMeta(path: path, created: created, modified: .now, size: data.count))
    }
}
