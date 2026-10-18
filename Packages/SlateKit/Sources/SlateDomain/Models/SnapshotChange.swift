import Foundation

package struct SnapshotChange: Identifiable, Hashable, Sendable {
    package let snapshot: Snapshot
    package let files: [ChangedFile]

    package var id: String {
        snapshot.hash
    }

    package init(snapshot: Snapshot, files: [ChangedFile]) {
        self.snapshot = snapshot
        self.files = files
    }
}
