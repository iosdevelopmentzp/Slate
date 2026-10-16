import Foundation

package struct CommandRecord: Sendable, Hashable {
    package let command: String
    package let cwd: String?
    package let exitCode: Int32?
    package let error: String?
    package let outputTail: [String]

    package var isFailure: Bool {
        error != nil || (exitCode.map { $0 != 0 } ?? false)
    }

    package init(command: String, cwd: String?, exitCode: Int32?, error: String?, outputTail: [String]) {
        self.command = command
        self.cwd = cwd
        self.exitCode = exitCode
        self.error = error
        self.outputTail = outputTail
    }
}
