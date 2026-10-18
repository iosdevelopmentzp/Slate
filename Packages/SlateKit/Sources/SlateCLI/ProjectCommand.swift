import ArgumentParser
import Foundation

struct ProjectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "project",
        abstract: "Show or link the Slate project of a code repository.",
        subcommands: [ProjectShowCommand.self, ProjectAddCommand.self],
        defaultSubcommand: ProjectShowCommand.self
    )
}
