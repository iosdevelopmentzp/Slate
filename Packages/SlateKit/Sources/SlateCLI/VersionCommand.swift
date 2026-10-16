import ArgumentParser
import Foundation

struct VersionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "version", abstract: "Print the version.")

    func run() throws {
        print("slate 0.0.1")
    }
}
