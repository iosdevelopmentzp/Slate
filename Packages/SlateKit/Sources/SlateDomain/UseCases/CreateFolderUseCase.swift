import Foundation

package struct CreateFolderUseCase: Sendable {
    let files: any VaultFileStore

    package func execute(name: String, in parent: FolderPath) async throws -> FolderPath {
        guard let valid = SpaceNamePolicy.validated(name) else { throw VaultError.invalidName(name) }
        let folder = parent.appending(valid.rawValue)
        let siblings = try await files.folders().filter { $0.parent == parent }
        guard siblings.contains(where: { StemPolicy.isSame($0.name, folder.name) }) == false else {
            throw VaultError.alreadyExists(folder.name)
        }
        try await files.createFolder(folder)
        return folder
    }
}
