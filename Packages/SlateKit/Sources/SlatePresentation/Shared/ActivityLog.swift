import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
package final class ActivityLog {
    static let limit = 50

    private(set) var events: [ActivityEvent]

    package init(events: [ActivityEvent] = []) {
        self.events = events
    }

    func log(_ title: String, detail: String, outcome: ActivityEvent.Outcome) {
        events.insert(ActivityEvent(id: UUID(), title: title, detail: detail, date: .now, outcome: outcome), at: 0)
        if events.count > Self.limit {
            events.removeLast(events.count - Self.limit)
        }
    }

    func handle(_ record: CommandRecord) {
        guard record.isFailure else { return }
        let message = record.error ?? record.outputTail.last ?? "Exited with code \(record.exitCode ?? -1)."
        log(record.command, detail: message, outcome: .failure)
    }

    func clear() {
        events.removeAll()
    }
}
