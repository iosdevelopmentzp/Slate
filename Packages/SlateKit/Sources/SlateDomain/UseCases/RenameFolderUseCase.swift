import Foundation

package struct RenameFolderUseCase: Sendable {
    let files: any VaultFileStore
    let reindex: ReindexVaultUseCase

    package func execute(_ folder: FolderPath, to name: String) async throws -> FolderPath {
        guard let parent = folder.parent else { throw VaultError.invalidName(name) }
        guard let valid = SpaceNamePolicy.validated(name) else { throw VaultError.invalidName(name) }
        let target = parent.appending(valid.rawValue)
        guard target != folder else { return folder }
        let caseOnly = StemPolicy.isSame(target.name, folder.name)
        let siblings = try await files.folders().filter { $0.parent == parent && $0 != folder }
        guard caseOnly || siblings.contains(where: { StemPolicy.isSame($0.name, target.name) }) == false else {
            throw VaultError.alreadyExists(target.name)
        }
        try await files.moveFolder(from: folder, to: target)
        _ = try await reindex.execute(.all)
        return target
    }
}
