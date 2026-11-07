import Foundation

package protocol AppUpdating: Sendable {
    func installed() async -> InstalledBuild?
    func newCommits(for build: InstalledBuild) async throws -> [UpdateCommit]
    func start(_ build: InstalledBuild) async throws
    func status() async -> UpdateStatus?
    func isRunning() async -> Bool
    func clearStatus() async
    func log() async -> String
}
