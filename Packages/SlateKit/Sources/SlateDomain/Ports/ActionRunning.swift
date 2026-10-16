import Foundation

package protocol ActionRunning: Sendable {
    func run(_ command: String, environment: [String: String], workingDirectory: URL) async throws -> ActionResult
}
