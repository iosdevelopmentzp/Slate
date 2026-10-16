import Foundation
import SlateDomain

package final class SpyLoginItem: LaunchAtLogin, @unchecked Sendable {
    private let lock = NSLock()
    private var _status: LoginItemStatus = .disabled
    private var _calls: [Bool] = []

    package init() {}

    package var calls: [Bool] {
        lock.withLock { _calls }
    }

    package var current: LoginItemStatus {
        get { lock.withLock { _status } }
        set { lock.withLock { _status = newValue } }
    }

    package func status() async -> LoginItemStatus {
        current
    }

    package func setEnabled(_ enabled: Bool) async throws {
        lock.withLock {
            _calls.append(enabled)
            _status = enabled ? .enabled : .disabled
        }
    }
}
