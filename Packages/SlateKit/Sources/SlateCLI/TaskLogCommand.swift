import ArgumentParser
import Foundation
import SlateDomain

struct TaskLogCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "log", abstract: "Add a dated entry to the Log section of a task note.")

    @Argument(help: "The task: its ticket, its folder or its title.") var task: String
    @Argument(help: "The text of the entry.") var text: String
    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        try await container.refreshIndex()
        guard let found = try await container.useCases.findTask.execute(task) else { throw CLIError.notFound(task) }
        let document = try await container.useCases.logProgress.execute(text, to: found.path)
        print(container.absolutePath(document.path))
    }
}
