import Foundation

package struct CreateProjectUseCase: Sendable {
    let createSpace: CreateSpaceUseCase
    let setProject: SetProjectUseCase

    package func execute(name: String, repositories: [String] = [], remote: String? = nil) async throws -> SpaceName {
        let space = try await createSpace.execute(name: name)
        try await setProject.execute(space, project: ProjectInfo(repositories: repositories, remote: remote))
        return space
    }
}
