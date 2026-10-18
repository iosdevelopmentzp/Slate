import ArgumentParser
import Foundation
import SlateDomain

struct ProjectShowCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "show", abstract: "Print the project of a repository with its tasks.")

    @Option(help: "The repository folder. Default: the current folder.") var repo: String?
    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        try await container.refreshIndex()
        let directory = CLIContainer.directory(repo)
        guard let match = try await container.useCases.findProject.execute(directory: directory) else {
            throw CLIError.nothingToDo("No Slate project belongs to \(directory.path). Run slate project add <Name> --repo \(directory.path).")
        }
        let tasks = try await container.useCases.projectTasks.execute(in: match.space.folder)
        let folder = container.root.appendingPathComponent(match.space.folder.rawValue, isDirectory: true).path
        if options.json {
            let object: [String: Any] = [
                "project": match.space.folder.rawValue,
                "absolutePath": folder,
                "tasks": tasks.map { ["title": $0.title, "status": $0.status.rawValue, "path": container.absolutePath($0.path)] },
            ]
            let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            print(String(decoding: data, as: UTF8.self))
            return
        }
        print("\(match.space.folder.rawValue)\t\(folder)")
        for task in tasks {
            print("  \(task.status.rawValue)\t\(task.title)")
        }
    }
}
