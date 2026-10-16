import ArgumentParser
import Foundation
import SlateDomain

struct AppendCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "append", abstract: "Add text to a note, under a heading when --section is given.")

    @Argument(help: "The text.") var text: String
    @Flag(help: "Add to today's note, under Log as a timed line.") var today = false
    @Option(help: "The ticket key. A ticket without a note gets a task note.") var ticket: String?
    @Option(help: "The note path inside the notes folder, like Notes/Plan.md.") var path: String?
    @Option(help: "The heading to add under. It is made when missing.") var section: String?
    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        let target: AppendTarget
        if today {
            target = .today
        } else if let ticket {
            try await container.refreshIndex()
            target = .ticket(ticket)
        } else if let path {
            target = .path(VaultPath(rawValue: path))
        } else {
            throw CLIError.nothingToDo("Pass --today, --ticket or --path.")
        }
        let document = try await container.useCases.append.execute(text, to: target, section: section)
        print(container.absolutePath(document.path))
    }
}
