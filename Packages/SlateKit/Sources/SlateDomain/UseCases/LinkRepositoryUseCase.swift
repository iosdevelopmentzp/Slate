import Foundation

package struct LinkRepositoryUseCase: Sendable {
    let config: any VaultConfigRepository
    let repositories: any RepositoryInspecting
    let setProject: SetProjectUseCase

    @discardableResult
    package func execute(_ project: SpaceName, directory: URL) async throws -> ProjectInfo {
        guard let space = try await config.spaces().space(project), var info = space.project else { throw TaskError.notAProject(project.rawValue) }
        let repository = await repositories.inspect(directory)
        let path = repository?.mainRoot ?? directory.standardizedFileURL.path
        info.repositories = [path] + info.repositories.filter { $0 != path }
        if let remote = repository?.remote {
            info.remote = remote
        }
        try await setProject.execute(project, project: info)
        return info
    }
}
