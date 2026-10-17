import Foundation
import SlateDomain

package final class SpyAgentChangeLog: AgentChangeLog, @unchecked Sendable {
    private let lock = NSLock()
    private var _changes: [AgentChange] = []

    package init() {}

    package var recorded: [AgentChange] {
        lock.withLock { _changes }
    }

    package func record(_ change: AgentChange) async throws {
        lock.withLock { _changes.append(change) }
    }

    package func changes(after date: Date) async throws -> [AgentChange] {
        lock.withLock { _changes.filter { $0.date > date } }
    }
}
