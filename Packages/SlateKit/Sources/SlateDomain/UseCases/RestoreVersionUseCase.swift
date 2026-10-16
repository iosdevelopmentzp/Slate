import Foundation

package struct RestoreVersionUseCase: Sendable {
    let history: any HistoryRepository
    let files: any VaultFileStore
    let save: SaveNoteUseCase

    package func execute(_ snapshot: Snapshot, of path: VaultPath) async throws -> SaveResult {
        try await history.ensureRepository()
        _ = try await history.snapshot(message: "before restore: \(path.rawValue)")
        let data = try await history.contents(of: path, at: snapshot.hash)
        let current = try NoteCodec.decode(try await files.read(path))
        let old = try NoteCodec.decode(FileContents(data: data, hash: .of(data), meta: current.meta))
        var header = old.header
        header.id = current.header.id ?? old.header.id
        header.title = current.header.title
        return try await save.execute(current, header: header, body: old.body)
    }
}
