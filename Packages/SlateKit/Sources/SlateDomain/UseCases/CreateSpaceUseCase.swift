import Foundation

package struct CreateSpaceUseCase: Sendable {
    let files: any VaultFileStore
    let config: any VaultConfigRepository

    package func execute(name: String) async throws -> SpaceName {
        guard let space = SpaceNamePolicy.validated(name) else { throw VaultError.invalidName(name) }
        var spaces = try await config.spaces()
        guard spaces.spaces.contains(where: { StemPolicy.isSame($0.folder.rawValue, space.rawValue) }) == false else {
            throw VaultError.alreadyExists(space.rawValue)
        }
        try await files.createFolder(space)
        spaces.spaces.append(Space(folder: space, icon: "folder.fill", defaultType: NoteType.defaultName))
        try await config.saveSpaces(spaces)
        return space
    }
}
