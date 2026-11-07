import Foundation
import SlateDomain

struct MockAppUpdater: AppUpdating {
    func installed() async -> InstalledBuild? {
        nil
    }

    func newCommits(for build: InstalledBuild) async throws -> [UpdateCommit] {
        []
    }

    func start(_ build: InstalledBuild) async throws {}

    func status() async -> UpdateStatus? {
        nil
    }

    func isRunning() async -> Bool {
        false
    }

    func clearStatus() async {}

    func log() async -> String {
        ""
    }
}
