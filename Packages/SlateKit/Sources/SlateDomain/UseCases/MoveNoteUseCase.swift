import Foundation

package struct MoveNoteUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding

    package func execute(_ path: VaultPath, to space: SpaceName) async throws -> VaultPath {
        guard path.space != space || path.depth > 1 else { return path }
        let stems = try await NoteStems.stems(inFolder: space.rawValue, files: files)
        let target = VaultPath(space: space, stem: StemPolicy.unique(path.stem, among: stems))
        try await files.move(from: path, to: target)
        try await index.remove(path: path)
        let document = try NoteCodec.decode(try await files.read(target))
        try await index.upsert(builder.build(document))
        return target
    }
}
