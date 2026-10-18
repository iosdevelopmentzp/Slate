import ArgumentParser
import Foundation
import SlateDomain

struct TaskStatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "status", abstract: "Set the status of a task: todo, active, review, done or dropped.")

    @Argument(help: "The task: its ticket, its folder or its title.") var task: String
    @Argument(help: "todo, active, review, done or dropped.") var status: String
    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        try await container.refreshIndex()
        guard let value = NoteStatus(rawValue: status.lowercased()) else {
            throw CLIError.nothingToDo("Use one of: \(NoteStatus.allCases.map(\.rawValue).joined(separator: ", ")).")
        }
        guard let found = try await container.useCases.findTask.execute(task) else { throw CLIError.notFound(task) }
        try await container.useCases.setTaskStatus.execute(found.path, status: value)
        print("\(found.title)\t\(value.rawValue)")
    }
}
