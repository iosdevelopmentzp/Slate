import Foundation

package struct SnapshotOutcome: Hashable, Sendable {
    package enum Push: Hashable, Sendable {
        case notConfigured
        case pushed
        case failed(String)
    }

    package var committed: Bool
    package var push: Push

    package init(committed: Bool, push: Push) {
        self.committed = committed
        self.push = push
    }
}
