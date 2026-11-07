import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct UpdateBadgeMapperTests {
    @Test func titlesFollowTheState() {
        let start = Date(timeIntervalSince1970: 0)
        let one = [UpdateCommit(hash: "a", subject: "x")]

        #expect(UpdateBadgeMapper.title(for: .idle, now: start) == nil)
        #expect(UpdateBadgeMapper.title(for: .available(one), now: start) == "Update available · 1 change")
        #expect(UpdateBadgeMapper.title(for: .running(.building, startedAt: start), now: Date(timeIntervalSince1970: 83)) == "Building · 1:23")
        #expect(UpdateBadgeMapper.title(for: .failed("x"), now: start) == "Update failed")
    }

    @Test func longListsAreCut() {
        let commits = (1...12).map { UpdateCommit(hash: "\($0)", subject: "change \($0)") }

        let lines = UpdateBadgeMapper.lines(of: commits)

        #expect(lines.count == 11)
        #expect(lines.last == "and 2 more")
    }
}
