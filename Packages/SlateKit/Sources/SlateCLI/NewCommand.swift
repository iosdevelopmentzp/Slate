import ArgumentParser
import Foundation
import SlateDomain

struct NewCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "new", abstract: "Make a new note and print its path.")

    @Argument(help: "The title.") var title: String
    @Option(help: "The kind: note, task, snippet, meeting or your own.") var type: String?
    @Option(help: "The folder.") var space: String?
    @Option(help: "The ticket key.") var ticket: String?
    @Option(help: "The text of the note.") var body: String?
    @Flag(help: "Show the note in Slate.") var open = false
    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        let created = try await container.useCases.create.execute(NoteDraft(title: title, type: type, space: space.map(SpaceName.init(rawValue:)), ticket: ticket, body: body.map { $0.hasSuffix("\n") ? $0 : $0 + "\n" }))
        print(container.absolutePath(created.document.path))
        if open {
            try await container.openInApp([URLQueryItem(name: "id", value: created.document.id.rawValue)], route: "open")
        }
    }
}
