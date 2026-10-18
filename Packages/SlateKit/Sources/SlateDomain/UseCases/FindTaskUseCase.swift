import Foundation

package struct FindTaskUseCase: Sendable {
    let config: any VaultConfigRepository
    let projectTasks: ProjectTasksUseCase

    package func execute(_ raw: String) async throws -> ProjectTask? {
        var tasks: [ProjectTask] = []
        for space in try await config.spaces().spaces where space.isProject {
            tasks += try await projectTasks.execute(in: space.folder)
        }
        let wanted = AgentPathPolicy.trimmed(raw)
        return tasks.first { $0.id.rawValue == wanted }
            ?? tasks.first { StemPolicy.isSame($0.path.rawValue, wanted) }
            ?? tasks.first { $0.folder.map { StemPolicy.isSame($0.rawValue, wanted) } ?? false }
            ?? tasks.first { $0.ticket.map { StemPolicy.isSame($0, wanted) } ?? false }
            ?? tasks.first { StemPolicy.isSame($0.title, wanted) }
    }
}
