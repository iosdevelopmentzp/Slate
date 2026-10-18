import Foundation

package struct StartTaskUseCase: Sendable {
    let files: any VaultFileStore
    let config: any VaultConfigRepository
    let create: CreateNoteUseCase
    let keyValues: any KeyValueStore

    package func execute(in project: SpaceName, title: String, ticket: String? = nil, branch: String? = nil) async throws -> CreatedNote {
        guard try await config.spaces().space(project)?.isProject == true else { throw TaskError.notAProject(project.rawValue) }
        let split = TitlePolicy.split(title, ticketPattern: TrackerSettings.load(from: keyValues).ticketPattern)
        let found = ticket.flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 } ?? split.ticket
        let name = TitlePolicy.render(NoteType.task.titlePattern, ticket: found, title: split.title)
        guard name.isEmpty == false else { throw VaultError.invalidName(title) }
        let parent = FolderPath(space: project)
        let siblings = try await files.folders().filter { $0.parent == parent }.map(\.name)
        let folder = parent.appending(StemPolicy.unique(StemPolicy.stem(forTitle: name), among: siblings))
        try await files.createFolder(folder)
        return try await create.execute(NoteDraft(title: name, type: NoteType.task.name, ticket: found, folder: folder, branch: branch, status: .active))
    }
}
