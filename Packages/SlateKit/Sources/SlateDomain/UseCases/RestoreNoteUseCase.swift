import Foundation

package struct RestoreNoteUseCase: Sendable {
    let trash: any TrashRepository
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding

    package func execute(_ item: TrashItem) async throws -> NoteDocument {
        let path = try await trash.restore(item)
        let document = try NoteCodec.decode(try await files.read(path))
        try await index.upsert(builder.build(document))
        return document
    }
}
