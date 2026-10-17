import Foundation
import SlateDomain

actor MockVaultFileStore: VaultFileStore {
    private var files: [VaultPath: (data: Data, meta: FileMeta)] = [:]
    private var folderSet: Set<FolderPath>

    init(documents: [NoteDocument] = MockVault.documents, spaces: [Space] = MockVault.spaces) {
        folderSet = Set(spaces.map { FolderPath(space: $0.folder) })
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

    func folders() -> [FolderPath] {
        let fromFiles = files.keys.compactMap(\.folderPath).filter { $0.isSpace == false }
        return Set(folderSet.filter { $0.isSpace == false } + fromFiles).sorted { $0.rawValue < $1.rawValue }
    }

    func createFolder(_ folder: FolderPath) {
        folderSet.insert(folder)
    }

    func removeFolder(_ folder: FolderPath) {
        folderSet = folderSet.filter { $0 != folder && folder.contains($0) == false }
    }

    func moveFolder(from source: FolderPath, to target: FolderPath) {
        folderSet = Set(folderSet.map { $0.moved(from: source, to: target) })
    }

    private func store(_ path: VaultPath, _ data: Data) {
        let created = files[path]?.meta.created ?? .now
        files[path] = (data, FileMeta(path: path, created: created, modified: .now, size: data.count))
    }
}
