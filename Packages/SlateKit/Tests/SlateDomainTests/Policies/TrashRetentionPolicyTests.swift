import Foundation
import Testing
@testable import SlateDomain

@Suite struct TrashRetentionPolicyTests {
    private let now = Date(timeIntervalSince1970: 10_000_000)

    private func item(_ days: Double) -> TrashItem {
        TrashItem(path: VaultPath(rawValue: "Inbox/\(days).md"), originalPath: VaultPath(rawValue: "Inbox/\(days).md"), trashedAt: now.addingTimeInterval(-days * 86_400))
    }

    @Test func itemsOlderThanTheRetentionAreDue() {
        let items = [item(1), item(29.9), item(30.1), item(90)]

        #expect(TrashRetentionPolicy.due(items, now: now, days: 30).map(\.path.rawValue) == ["Inbox/30.1.md", "Inbox/90.0.md"])
        #expect(TrashRetentionPolicy.due(items, now: now, days: 0).isEmpty)
    }

    @Test func daysLeftCountsDown() {
        #expect(TrashRetentionPolicy.daysLeft(for: item(3.5), now: now, days: 30) == 27)
        #expect(TrashRetentionPolicy.daysLeft(for: item(40), now: now, days: 30) == 0)
    }
}
