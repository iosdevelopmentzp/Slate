import Foundation
import SlateDomain
import SlateMocks
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct AgentMarksTests {
    private let store = InMemoryKeyValueStore()
    private let log = SpyAgentChangeLog()
    private let plan = VaultPath(rawValue: "Work/Plan.md")

    private func change(_ seconds: TimeInterval, _ path: VaultPath) async throws {
        try await log.record(AgentChange(date: Date(timeIntervalSince1970: seconds), tool: "update_section", title: path.stem, path: path))
    }

    @Test func aChangeByAnAgentMarksTheNoteUntilItIsRead() async throws {
        let marks = AgentMarks(store: store, log: log, now: Date(timeIntervalSince1970: 10))
        try await change(5, VaultPath(rawValue: "Old.md"))
        try await change(20, plan)
        try await change(30, plan)

        await marks.refresh()

        #expect(marks.since(plan) == Date(timeIntervalSince1970: 20))
        #expect(marks.since(VaultPath(rawValue: "Old.md")) == nil)
        marks.markRead(plan)
        #expect(marks.since(plan) == nil)
    }

    @Test func marksSurviveARestart() async throws {
        let marks = AgentMarks(store: store, log: log, now: Date(timeIntervalSince1970: 10))
        try await change(20, plan)
        await marks.refresh()

        let again = AgentMarks(store: store, log: log, now: Date(timeIntervalSince1970: 99))
        await again.refresh()

        #expect(again.since(plan) == Date(timeIntervalSince1970: 20))
    }

    @Test func aChangeWhileTheAppWasClosedIsFound() async throws {
        let marks = AgentMarks(store: store, log: log, now: Date(timeIntervalSince1970: 10))
        await marks.refresh()
        marks.markRead(plan)
        try await change(20, plan)

        let later = AgentMarks(store: store, log: log, now: Date(timeIntervalSince1970: 99))
        await later.refresh()

        #expect(later.since(plan) == Date(timeIntervalSince1970: 20))
    }
}
