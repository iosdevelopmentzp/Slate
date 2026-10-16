import Foundation
import SlateDomain

nonisolated package struct ActivityRecorder: CommandRecording {
    let log: ActivityLog

    package init(log: ActivityLog) {
        self.log = log
    }

    package func record(_ record: CommandRecord) {
        Task { @MainActor in
            log.handle(record)
        }
    }
}
