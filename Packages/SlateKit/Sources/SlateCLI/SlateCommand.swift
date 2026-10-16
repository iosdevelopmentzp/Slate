import ArgumentParser
import Foundation

@main
struct SlateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "slate",
        abstract: "Notes from the command line.",
        subcommands: [VersionCommand.self]
    )
}
