import ArgumentParser
import Foundation
import SlateDomain

struct ProjectAddCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "add", abstract: "Make a project, or make a folder a project, and link a repository to it.")

    @Argument(help: "The project name in Slate.") var name: String
    @Option(help: "The repository folder. Default: the current folder.") var repo: String?
    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        let useCases = container.useCases
        let spaces = try await container.ports.config.spaces().spaces
        let space: SpaceName
        if let existing = spaces.first(where: { StemPolicy.isSame($0.folder.rawValue, name) }) {
            space = existing.folder
            if existing.isProject == false {
                try await useCases.setProject.execute(space, project: ProjectInfo())
            }
        } else {
            space = try await useCases.createProject.execute(name: name)
        }
        let info = try await useCases.linkRepository.execute(space, directory: CLIContainer.directory(repo))
        print("\(space.rawValue)\t\(container.root.appendingPathComponent(space.rawValue, isDirectory: true).path)")
        if let remote = info.remote {
            print("  remote\t\(remote)")
        }
    }
}
