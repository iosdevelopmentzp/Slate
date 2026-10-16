import Foundation
import SlateDomain

struct MockActionRunner: ActionRunning {
    func run(_ command: String, environment: [String: String], workingDirectory: URL) async throws -> ActionResult {
        ActionResult(output: "", exitCode: 0)
    }
}
