import Foundation

package struct ArchiveNoteUseCase: Sendable {
    let config: any VaultConfigRepository
    let move: MoveNoteUseCase

    package func execute(_ path: VaultPath) async throws -> VaultPath {
        try await move.execute(path, to: try await config.spaces().archiveSpace)
    }
}
