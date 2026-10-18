import ArgumentParser
import Foundation
import SlateDomain

struct TaskNewCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "new", abstract: "Start a task: a task folder and a task note. Prints the path of the note.")

    @Argument(help: "The title, like \"ABC-123 Fix login\".") var title: String
    @Option(help: "The ticket, when it is not in the title.") var ticket: String?
    @Option(help: "The git branch. Default: the current branch.") var branch: String?
    @Option(help: "The project name. Default: the project of the repository.") var project: String?
    @Option(help: "The repository folder. Default: the current folder.") var repo: String?
    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        let directory = CLIContainer.directory(repo)
        let match: ProjectMatch?
        if let project {
            match = try await container.useCases.findProject.execute(named: project).map { ProjectMatch(space: $0, repository: nil) }
        } else {
            match = try await container.useCases.findProject.execute(directory: directory)
        }
        guard let match else {
            throw CLIError.nothingToDo("No Slate project found. Pass --project <Name>, or run slate project add <Name> --repo \(directory.path).")
        }
        var repository = match.repository
        if repository == nil {
            repository = await container.ports.repositories.inspect(directory)
        }
        let current = branch ?? repository?.branch
        let created = try await container.useCases.startTask.execute(in: match.space.folder, title: title, ticket: ticket, branch: current)
        print(container.absolutePath(created.document.path))
    }
}
