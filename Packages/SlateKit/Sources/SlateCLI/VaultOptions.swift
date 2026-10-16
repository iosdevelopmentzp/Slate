import ArgumentParser
import Foundation

struct VaultOptions: ParsableArguments {
    @Option(name: .long, help: "The notes folder. Default: SLATE_VAULT or the folder Slate uses.")
    var vault: String?

    @Flag(name: .long, help: "Print JSON.")
    var json = false

    @Option(name: .long, help: .hidden)
    var supportFolder: String?
}
