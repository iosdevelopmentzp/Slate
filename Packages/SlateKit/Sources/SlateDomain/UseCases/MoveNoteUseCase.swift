import Foundation

package struct MoveNoteUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding

    package func execute(_ path: VaultPath, to space: SpaceName) async throws -> VaultPath {
        try await execute(path, toFolder: FolderPath(space: space))
    }

    package func execute(_ path: VaultPath, toFolder folder: FolderPath, stem: String? = nil) async throws -> VaultPath {
        guard path.folder != folder.rawValue else { return path }
        let stems = try await NoteStems.stems(inFolder: folder.rawValue, files: files)
        let target = VaultPath(folder: folder, stem: StemPolicy.unique(stem ?? path.stem, among: stems))
        try await files.move(from: path, to: target)
        try await index.remove(path: path)
        var contents = try await files.read(target)
        if path.depth != target.depth {
            let text = String(decoding: contents.data, as: UTF8.self)
            let rewritten = AttachmentPolicy.rewriteLinks(in: text, from: path, to: target)
            if rewritten != text {
                _ = try await files.write(target, data: Data(rewritten.utf8), expected: contents.hash)
                contents = try await files.read(target)
            }
        }
        let document = try NoteCodec.decode(contents)
        try await index.upsert(builder.build(document))
        return target
    }
}
