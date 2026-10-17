import ArgumentParser
import Foundation

struct VersionCommand: ParsableCommand {
    static let version = "0.0.1"
    static let configuration = CommandConfiguration(commandName: "version", abstract: "Print the version.")

    func run() throws {
        print("slate \(Self.version)")
    }
}
