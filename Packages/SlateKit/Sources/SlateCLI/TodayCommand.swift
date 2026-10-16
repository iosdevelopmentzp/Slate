import ArgumentParser
import Foundation
import SlateDomain

struct TodayCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "today", abstract: "Print the path of today's note; make it when missing.")

    @Flag(help: "Show it in Slate.") var open = false
    @OptionGroup var options: VaultOptions

    func run() async throws {
        let container = try CLIContainer(options: options)
        let daily = try await container.useCases.ensureDaily.execute()
        print(container.absolutePath(daily.document.path))
        if open {
            try await container.openInApp([URLQueryItem(name: "id", value: daily.document.id.rawValue)], route: "open")
        }
    }
}
