import Foundation
import SlateDomain

package final class SpyClock: Clock, @unchecked Sendable {
    private let lock = NSLock()
    private var _now = Date(timeIntervalSince1970: 1_800_000_000)

    package init() {}

    package var current: Date {
        get { lock.withLock { _now } }
        set { lock.withLock { _now = newValue } }
    }

    package func now() -> Date {
        current
    }

    package var timeZone: TimeZone {
        TimeZone(secondsFromGMT: 3 * 3_600) ?? .gmt
    }
}
