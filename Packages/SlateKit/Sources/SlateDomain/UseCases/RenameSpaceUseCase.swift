import Foundation

package struct RenameSpaceUseCase: Sendable {
    let files: any VaultFileStore
    let config: any VaultConfigRepository
    let reindex: ReindexVaultUseCase

    package func execute(_ space: SpaceName, to name: String) async throws -> SpaceName {
        guard let target = SpaceNamePolicy.validated(name) else { throw VaultError.invalidName(name) }
        guard target != space else { return space }
        var spaces = try await config.spaces()
        let caseOnly = StemPolicy.isSame(target.rawValue, space.rawValue)
        guard caseOnly || spaces.spaces.contains(where: { StemPolicy.isSame($0.folder.rawValue, target.rawValue) }) == false else {
            throw VaultError.alreadyExists(target.rawValue)
        }
        try await files.moveFolder(from: space, to: target)
        spaces.spaces = spaces.spaces.map { entry in
            guard entry.folder == space else { return entry }
            return Space(folder: target, icon: entry.icon, defaultType: entry.defaultType, noteCount: entry.noteCount)
        }
        if spaces.captureSpace == space { spaces.captureSpace = target }
        if spaces.archiveSpace == space { spaces.archiveSpace = target }
        if spaces.dailySpace == space { spaces.dailySpace = target }
        try await config.saveSpaces(spaces)
        _ = try await reindex.execute(.all)
        return target
    }
}
