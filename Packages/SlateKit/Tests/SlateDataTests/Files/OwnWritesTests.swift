import Foundation
import SlateDomain
import Testing
@testable import SlateData

@Suite struct OwnWritesTests {
    private let path = VaultPath(rawValue: "Inbox/A.md")
    private let hash = ContentHash(rawValue: "h")

    @Test func recentWriteWithTheSameHashIsOwn() {
        let writes = OwnWrites()
        let now = Date()

        writes.record(path, hash: hash, at: now)

        #expect(writes.isOwn(path, diskHash: hash, at: now.addingTimeInterval(1)))
        #expect(writes.isOwn(path, diskHash: ContentHash(rawValue: "other"), at: now) == false)
    }

    @Test func oldWriteIsNotOwn() {
        let writes = OwnWrites()
        let now = Date()

        writes.record(path, hash: hash, at: now)

        #expect(writes.isOwn(path, diskHash: hash, at: now.addingTimeInterval(OwnWrites.window + 1)) == false)
    }
}
