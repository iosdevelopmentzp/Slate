import Foundation

struct ShellResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32

    var failureMessage: String {
        let error = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        let output = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = error.isEmpty ? output : error
        return message.isEmpty ? "Exited with code \(exitCode)." : message
    }

    var lines: [String] {
        [stdout, stderr]
            .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .flatMap { text in
                var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
                if lines.last == "" {
                    lines.removeLast()
                }
                return lines
            }
    }
}
