import ArgumentParser
import Foundation
import SlateDomain

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "list", abstract: "List notes, newest first.")

    @Option(help: "Only this folder.") var space: String?
    @Option(help: "Only this status.") var status: String?
    @Option(help: "Only this kind.") var type: String?
    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        try await container.refreshIndex()
        var summaries = try await container.ports.index.summaries(space: space.map(SpaceName.init(rawValue:)))
        if let status {
            summaries = summaries.filter { $0.status?.rawValue == status }
        }
        if let type {
            summaries = summaries.filter { $0.type == type }
        }
        CLIContainer.print(summaries, json: options.json, root: container.root)
    }
}
