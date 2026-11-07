import Foundation
import SlateDomain

package final class SpyAppUpdater: AppUpdating, @unchecked Sendable {
    private let lock = NSLock()
    private var _installed: InstalledBuild?
    private var _commits: [UpdateCommit] = []
    private var _status: UpdateStatus?
    private var _running = false
    private var _started: [InstalledBuild] = []
    private var _checks = 0
    private var _failure: (any Error)?
    private var _statusAfterStart: UpdateStatus?

    package init() {}

    package var build: InstalledBuild? {
        get { lock.withLock { _installed } }
        set { lock.withLock { _installed = newValue } }
    }

    package var commits: [UpdateCommit] {
        get { lock.withLock { _commits } }
        set { lock.withLock { _commits = newValue } }
    }

    package var currentStatus: UpdateStatus? {
        get { lock.withLock { _status } }
        set { lock.withLock { _status = newValue } }
    }

    package var running: Bool {
        get { lock.withLock { _running } }
        set { lock.withLock { _running = newValue } }
    }

    package var failure: (any Error)? {
        get { lock.withLock { _failure } }
        set { lock.withLock { _failure = newValue } }
    }

    package var statusAfterStart: UpdateStatus? {
        get { lock.withLock { _statusAfterStart } }
        set { lock.withLock { _statusAfterStart = newValue } }
    }

    package var started: [InstalledBuild] {
        lock.withLock { _started }
    }

    package var checks: Int {
        lock.withLock { _checks }
    }

    package func installed() async -> InstalledBuild? {
        build
    }

    package func newCommits(for build: InstalledBuild) async throws -> [UpdateCommit] {
        try lock.withLock {
            _checks += 1
            if let _failure { throw _failure }
            return _commits
        }
    }

    package func start(_ build: InstalledBuild) async throws {
        lock.withLock {
            _started.append(build)
            _status = _statusAfterStart
        }
    }

    package func status() async -> UpdateStatus? {
        currentStatus
    }

    package func isRunning() async -> Bool {
        running
    }

    package func clearStatus() async {
        currentStatus = nil
    }

    package func log() async -> String {
        "build log"
    }
}
