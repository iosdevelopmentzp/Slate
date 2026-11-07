import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct VersionRowMapperTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func aNamedVersionShowsItsName() {
        let model = VersionRowMapper.model(for: Snapshot(hash: "a", date: now, message: "version: before refactor"), now: now)

        #expect(model.title == "before refactor")
        #expect(model.isNamed)
        #expect(model.badge == nil)
    }

    @Test func anAgentVersionHasTheAgentBadge() {
        let model = VersionRowMapper.model(for: Snapshot(hash: "a", date: now, message: "agent: log_progress ABC-1 Fix"), now: now)

        #expect(model.isNamed == false)
        #expect(model.badge == VersionRowMapper.agentBadge)
        #expect(model.title.isEmpty == false)
    }

    @Test func aChangeSaysWhatHappenedInPlainWords() {
        func summary(_ message: String) -> String {
            VersionRowMapper.summary(of: SnapshotChange(snapshot: Snapshot(hash: "a", date: now, message: message), files: []))
        }

        #expect(summary("agent: log_progress ABC-1 Fix") == "Logged progress in ABC-1 Fix")
        #expect(summary("agent: add_file crash.log") == "Added crash.log")
        #expect(summary("version: done") == "done")
        #expect(summary("snapshot: 3 files") == "Saved by Slate")
        #expect(summary("history of MyApp cleared") == "History cleared")
    }

    @Test func theVersionBeforeAChangeIsTheNewestNotLaterThanIt() {
        let old = Snapshot(hash: "a", date: Date(timeIntervalSince1970: 100), message: "auto")
        let before = Snapshot(hash: "b", date: Date(timeIntervalSince1970: 200), message: "agent: update_section")
        let after = Snapshot(hash: "c", date: Date(timeIntervalSince1970: 300), message: "auto")

        #expect(VersionRowMapper.version(before: Date(timeIntervalSince1970: 250), in: [after, before, old]) == before)
        #expect(VersionRowMapper.version(before: Date(timeIntervalSince1970: 50), in: [after, before, old]) == nil)
    }
}
