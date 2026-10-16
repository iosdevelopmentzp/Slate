import Foundation

package struct TrashNoteUseCase: Sendable {
    let trash: any TrashRepository
    let index: any SearchIndex
    let clock: any Clock

    package func execute(_ path: VaultPath) async throws -> TrashItem {
        let item = try await trash.trash(path, at: clock.now())
        try await index.remove(path: path)
        return item
    }
}
