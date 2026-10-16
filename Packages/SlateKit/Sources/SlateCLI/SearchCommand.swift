import ArgumentParser
import Foundation
import SlateDomain

struct SearchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "search", abstract: "Search the notes. Filters like tag: and type: work.")

    @Argument(help: "The search, in quotes.") var query: String
    @Option(help: "Only this kind.") var type: String?
    @Option(help: "At most this many results.") var limit = 20
    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        try await container.refreshIndex()
        var parsed = SearchQueryParser.parse(query, now: Date(), timeZone: .current)
        if let type {
            parsed.filters.append(.type(type))
        }
        let hits = try await container.ports.index.search(parsed, limit: limit)
        CLIContainer.print(hits.map(\.summary), json: options.json, root: container.root)
    }
}
