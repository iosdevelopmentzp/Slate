import ArgumentParser
import Foundation
import SlateDomain

struct PathCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "path", abstract: "Print the file path of a note.")

    @Option(help: "The ticket key.") var ticket: String?
    @Option(help: "The title.") var title: String?
    @Option(help: "The note id.") var id: String?
    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        try await container.refreshIndex()
        guard ticket != nil || title != nil || id != nil else { throw CLIError.nothingToDo("Pass --ticket, --title or --id.") }
        guard let summary = try await container.find(ticket: ticket, title: title, id: id) else {
            throw CLIError.notFound(ticket ?? title ?? id ?? "")
        }
        print(container.absolutePath(summary.path))
    }
}
