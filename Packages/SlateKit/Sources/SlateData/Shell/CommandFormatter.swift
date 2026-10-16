import Foundation
import SlateDomain

enum CommandFormatter {

    static func displayCommand(_ executable: String, _ arguments: [String]) -> String {
        ([executable] + arguments.map(quoted)).joined(separator: " ")
    }

    private static func quoted(_ argument: String) -> String {
        guard argument.isEmpty || argument.contains(where: { $0.isWhitespace || "'\"$`\\\\".contains($0) }) else { return argument }
        if argument.contains("\n") { return "'…script…'" }
        return "'" + argument.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
