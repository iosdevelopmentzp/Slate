import Foundation

package struct FindProjectUseCase: Sendable {
    let config: any VaultConfigRepository
    let repositories: any RepositoryInspecting

    package func execute(directory: URL) async throws -> ProjectMatch? {
        let repository = await repositories.inspect(directory)
        let spaces = try await config.spaces().spaces
        guard let space = ProjectLookupPolicy.project(for: directory.standardizedFileURL.path, repository: repository, among: spaces) else { return nil }
        return ProjectMatch(space: space, repository: repository)
    }

    package func execute(named name: String) async throws -> Space? {
        try await config.spaces().spaces.first { $0.isProject && StemPolicy.isSame($0.folder.rawValue, name) }
    }
}
