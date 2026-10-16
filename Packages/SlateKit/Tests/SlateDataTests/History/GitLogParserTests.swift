import Foundation
import SlateDomain
import Testing
@testable import SlateData

@Suite struct GitLogParserTests {
    @Test func linesBecomeSnapshots() {
        let output = "0123456789abcdef\t1800000000\tsnapshot: 2 files\nfedcba9876543210\t1799999000\twith\ttab\nbad line\n"

        let snapshots = GitLogParser.snapshots(from: output)

        #expect(snapshots == [
            Snapshot(hash: "0123456789abcdef", date: Date(timeIntervalSince1970: 1_800_000_000), message: "snapshot: 2 files"),
            Snapshot(hash: "fedcba9876543210", date: Date(timeIntervalSince1970: 1_799_999_000), message: "with\ttab"),
        ])
    }
}
