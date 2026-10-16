import Foundation

package struct DuplicateNoteUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding
    let clock: any Clock

    package func execute(_ path: VaultPath) async throws -> NoteDocument {
        let original = try NoteCodec.decode(try await files.read(path))
        let stems = try await NoteStems.stems(inFolder: path.folder, files: files)
        let target = path.replacingStem(with: StemPolicy.unique(path.stem, among: stems))
        let now = clock.now()
        var header = original.header
        if original.isHeaderOpaque == false {
            header.id = .generate()
            header.title = original.title
            header.created = now
            header.updated = now
        }
        let data = NoteCodec.encode(header: header, body: original.body, opaqueHeader: original.opaqueHeader, timeZone: clock.timeZone)
        let hash = try await files.create(target, data: data)
        let meta = try await files.meta(target) ?? FileMeta(path: target, created: now, modified: now, size: data.count)
        let document = NoteDocument(path: target, header: header, body: original.body, hash: hash, meta: meta, opaqueHeader: original.opaqueHeader)
        try await index.upsert(builder.build(document))
        return document
    }
}
