import Foundation

package struct UpdateStatus: Hashable, Sendable {
    package enum Phase: String, Hashable, Sendable {
        case fetching
        case building
        case installing
        case done
        case failed

        package var isRunning: Bool {
            self == .fetching || self == .building || self == .installing
        }
    }

    package var phase: Phase
    package var startedAt: Date
    package var commit: String?
    package var message: String?

    package init(phase: Phase, startedAt: Date, commit: String? = nil, message: String? = nil) {
        self.phase = phase
        self.startedAt = startedAt
        self.commit = commit
        self.message = message
    }
}
