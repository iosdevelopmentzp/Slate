import Foundation

package struct CommandRecord: Sendable, Hashable {
    package let command: String
    package let cwd: String?
    package let exitCode: Int32?
    package let error: String?
    package let outputTail: [String]
    package let toleratedExitCodes: Set<Int32>

    package var isFailure: Bool {
        error != nil || (exitCode.map { $0 != 0 && toleratedExitCodes.contains($0) == false } ?? false)
    }

    package init(command: String, cwd: String?, exitCode: Int32?, error: String?, outputTail: [String], toleratedExitCodes: Set<Int32> = []) {
        self.command = command
        self.cwd = cwd
        self.exitCode = exitCode
        self.error = error
        self.outputTail = outputTail
        self.toleratedExitCodes = toleratedExitCodes
    }
}
