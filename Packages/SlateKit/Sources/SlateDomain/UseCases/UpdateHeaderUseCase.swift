import Foundation

package struct UpdateHeaderUseCase: Sendable {
    let files: any VaultFileStore
    let save: SaveNoteUseCase

    package func execute(_ path: VaultPath, change: @Sendable (inout NoteHeader) -> Void) async throws -> SaveResult {
        let document = try NoteCodec.decode(try await files.read(path))
        var header = document.header
        change(&header)
        return try await save.execute(document, header: header, body: document.body)
    }
}
