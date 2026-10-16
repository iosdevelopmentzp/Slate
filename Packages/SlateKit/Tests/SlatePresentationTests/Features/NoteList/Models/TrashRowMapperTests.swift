import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@Suite struct TrashRowMapperTests {
    @Test func showsTheStemAndTheOriginalFolder() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let item = TrashItem(path: VaultPath(rawValue: "Tasks/Old 2.md"), originalPath: VaultPath(rawValue: "Tasks/Old.md"), trashedAt: now.addingTimeInterval(-3_600))

        let model = TrashRowMapper.model(for: item, now: now)

        #expect(model.title == "Old")
        #expect(model.detail.hasPrefix("From Tasks · "))
        #expect(model.id == item.path)
    }
}
