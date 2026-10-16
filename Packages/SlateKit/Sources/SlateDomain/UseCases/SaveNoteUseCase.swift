import Foundation

package struct SaveNoteUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex
    let builder: any IndexedNoteBuilding
    let clock: any Clock

    package func execute(_ document: NoteDocument, header edited: NoteHeader, body: String) async throws -> SaveResult {
        guard edited != document.header || body != document.body else { return .unchanged(document) }
        var header = edited
        if document.isHeaderOpaque == false {
            header.id = header.id ?? .generate()
            header.title = header.title ?? document.title
            header.created = header.created ?? document.meta.created
            header.updated = clock.now()
        }
        let data = NoteCodec.encode(header: header, body: body, opaqueHeader: document.opaqueHeader, timeZone: clock.timeZone)
        switch try await files.write(document.path, data: data, expected: document.hash) {
        case .conflict(let diskHash):
            return .conflict(diskHash: diskHash)
        case .written(let hash):
            let now = clock.now()
            let meta = try await files.meta(document.path) ?? FileMeta(path: document.path, created: document.meta.created, modified: now, size: data.count)
            let saved = NoteDocument(path: document.path, header: header, body: body, hash: hash, meta: meta, opaqueHeader: document.opaqueHeader)
            try await index.upsert(builder.build(saved))
            return .saved(saved)
        }
    }
}
