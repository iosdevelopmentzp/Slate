import Foundation
import SlateDomain

package final class SpyCommandRecorder: CommandRecording, @unchecked Sendable {
    private let lock = NSLock()
    private var _records: [CommandRecord] = []

    package init() {}

    package var records: [CommandRecord] {
        lock.withLock { _records }
    }

    package func record(_ record: CommandRecord) {
        lock.withLock { _records.append(record) }
    }
}
