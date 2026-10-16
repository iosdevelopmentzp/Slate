import Foundation
import SlateDomain

package final class SpyIssueTracker: IssueTrackerClient, @unchecked Sendable {
    private let lock = NSLock()
    private var _issues: [String: IssueDetails] = [:]
    private var _calls: [String] = []
    private var _error: TrackerError?

    package init() {}

    package var calls: [String] {
        lock.withLock { _calls }
    }

    package var error: TrackerError? {
        get { lock.withLock { _error } }
        set { lock.withLock { _error = newValue } }
    }

    package func seed(_ issue: IssueDetails) {
        lock.withLock { _issues[issue.key] = issue }
    }

    package func issue(_ key: String) async throws -> IssueDetails {
        try lock.withLock {
            _calls.append(key)
            if let _error { throw _error }
            guard let issue = _issues[key] else { throw TrackerError.rejected(404) }
            return issue
        }
    }

    package func currentUser() async throws -> String {
        try lock.withLock {
            if let _error { throw _error }
            return "Test User"
        }
    }
}
