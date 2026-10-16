import ArgumentParser
import Foundation
import SlateDomain

struct OpenCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "open", abstract: "Show a note in Slate. A ticket without a note gets a task note.")

    @Option(help: "The ticket key.") var ticket: String?
    @Option(help: "The title.") var title: String?
    @Option(help: "The note id.") var id: String?

    func run() async throws {
        let item: URLQueryItem
        if let ticket {
            item = URLQueryItem(name: "ticket", value: ticket)
        } else if let id {
            item = URLQueryItem(name: "id", value: id)
        } else if let title {
            item = URLQueryItem(name: "title", value: title)
        } else {
            throw CLIError.nothingToDo("Pass --ticket, --title or --id.")
        }
        var components = URLComponents()
        components.scheme = "slate"
        components.host = "open"
        components.queryItems = [item]
        guard let url = components.url else { return }
        let process = try await CLIShell.open(url)
        if process != 0 { throw ExitCode(process) }
    }
}
