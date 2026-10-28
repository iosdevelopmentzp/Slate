import Foundation

package struct ProjectTasksUseCase: Sendable {
    let files: any VaultFileStore
    let index: any SearchIndex

    package func execute(in project: SpaceName) async throws -> [ProjectTask] {
        let summaries = try await index.summaries(space: project).filter { $0.type == NoteType.task.name && $0.path.depth >= 2 }
        var tasks: [ProjectTask] = []
        for summary in summaries {
            let header = (try? NoteCodec.decode(try await files.read(summary.path)))?.header
            tasks.append(ProjectTask(
                id: summary.id,
                path: summary.path,
                title: summary.title,
                status: summary.status ?? .todo,
                ticket: summary.ticket,
                branch: header?.branch,
                updated: summary.updated
            ))
        }
        return tasks.sorted { $0.updated > $1.updated }
    }
}
