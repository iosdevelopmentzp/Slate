import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite struct FileAgentChangeLogTests {
    private let folder: TemporaryDirectory
    private let log: FileAgentChangeLog

    init() throws {
        folder = try TemporaryDirectory()
        log = FileAgentChangeLog(url: folder.url.appendingPathComponent("support/\(FileAgentChangeLog.fileName)"))
    }

    private func change(_ seconds: TimeInterval, _ title: String) -> AgentChange {
        AgentChange(date: Date(timeIntervalSince1970: 1_800_000_000 + seconds), tool: "append_to_note", title: title, path: VaultPath(rawValue: "Notes/\(title).md"))
    }

    @Test func changesAfterADateComeBackInOrder() async throws {
        try await log.record(change(1, "A"))
        try await log.record(change(2, "B"))
        try await log.record(change(3, "C"))

        #expect(try await log.changes(after: Date(timeIntervalSince1970: 1_800_000_001)).map(\.title) == ["B", "C"])
    }

    @Test func aMissingFileHasNoChanges() async throws {
        #expect(try await log.changes(after: .distantPast).isEmpty)
    }

    @Test func onlyTheLastChangesAreKept() async throws {
        for second in 0..<(FileAgentChangeLog.keep + 5) {
            try await log.record(change(TimeInterval(second), "N\(second)"))
        }

        let kept = try await log.changes(after: .distantPast)
        #expect(kept.count == FileAgentChangeLog.keep)
        #expect(kept.first?.title == "N5")
    }
}
