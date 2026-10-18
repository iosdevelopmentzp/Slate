import Foundation

package struct SetTaskStatusUseCase: Sendable {
    let files: any VaultFileStore
    let updateHeader: UpdateHeaderUseCase

    @discardableResult
    package func execute(_ path: VaultPath, status: NoteStatus) async throws -> SaveResult {
        let document = try NoteCodec.decode(try await files.read(path))
        guard document.header.type == NoteType.task.name else { throw TaskError.notATask(path.stem) }
        return try await updateHeader.execute(path) { $0.status = status.rawValue }
    }
}
