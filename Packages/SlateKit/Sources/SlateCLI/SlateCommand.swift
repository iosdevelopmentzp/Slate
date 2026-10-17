import ArgumentParser
import Foundation

@main
struct SlateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "slate",
        abstract: "Notes from the command line. Works when Slate is not running.",
        subcommands: [NewCommand.self, OpenCommand.self, AppendCommand.self, TodayCommand.self, SearchCommand.self, ListCommand.self, PathCommand.self, MCPCommand.self, VersionCommand.self]
    )
}
