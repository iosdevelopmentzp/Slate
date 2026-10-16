import Foundation
import SlateDomain

struct ShellActionRunner: ActionRunning {
    static let timeout: Duration = .seconds(60)

    let shell: ShellRunner

    func run(_ command: String, environment: [String: String], workingDirectory: URL) async throws -> ActionResult {
        let expanded = (command as NSString).expandingTildeInPath
        let collector = OutputCollector()
        let status = try await withThrowingTaskGroup(of: Int32?.self) { group in
            group.addTask {
                try await shell.stream("/bin/zsh", ["-c", expanded], cwd: workingDirectory.path, environment: environment) { line in
                    collector.append(line)
                }
            }
            group.addTask {
                try await Task.sleep(for: Self.timeout)
                return nil
            }
            let first = try await group.next() ?? nil
            group.cancelAll()
            return first
        }
        guard let status else { throw ActionError.timedOut }
        return ActionResult(output: collector.text, exitCode: status)
    }
}

private final class OutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = []

    func append(_ line: String) {
        lock.withLock { lines.append(line) }
    }

    var text: String {
        lock.withLock { lines.joined(separator: "\n") }
    }
}
