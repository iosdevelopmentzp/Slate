import Foundation
import Testing
@testable import SlateDomain

@Suite struct SnapshotTests {
    @Test func snapshotsKnowTheirNameAndTheAgent() {
        #expect(Snapshot(hash: "a", date: .now, message: "version: v1").versionName == "v1")
        #expect(Snapshot(hash: "a", date: .now, message: "version:  ").versionName == nil)
        #expect(Snapshot(hash: "a", date: .now, message: "agent: start_task X").isByAgent)
        #expect(Snapshot(hash: "a", date: .now, message: "snapshot: 1 file").isByAgent == false)
    }
}
