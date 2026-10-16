import Foundation
import SlateDomain

package final class SpyActionRunner: ActionRunning, @unchecked Sendable {
    package struct Call: Hashable {
        package let command: String
        package let environment: [String: String]
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _result = ActionResult(output: "done", exitCode: 0)

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var result: ActionResult {
        get { lock.withLock { _result } }
        set { lock.withLock { _result = newValue } }
    }

    package func run(_ command: String, environment: [String: String], workingDirectory: URL) async throws -> ActionResult {
        lock.withLock {
            _calls.append(Call(command: command, environment: environment))
            return _result
        }
    }
}
