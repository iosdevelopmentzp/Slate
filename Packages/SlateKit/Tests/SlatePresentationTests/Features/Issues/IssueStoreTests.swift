import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct IssueStoreTests {
    private let harness = StoreHarness()

    @Test func withoutATokenNothingIsFetched() async {
        await harness.issues.refreshToken()

        await harness.issues.load("ABC-1")

        #expect(harness.spies.tracker.calls.isEmpty)
    }

    @Test func detailsLoadOnceWithAToken() async throws {
        harness.spies.tracker.seed(IssueDetails(key: "ABC-1", summary: "Fix", status: "Open", assignee: nil))
        try await harness.issues.saveToken(" secret ")

        await harness.issues.load("ABC-1")
        await harness.issues.load("ABC-1")

        #expect(harness.issues.details["ABC-1"]?.summary == "Fix")
        #expect(harness.spies.tracker.calls == ["ABC-1"])
        #expect(harness.spies.secrets.values[TrackerSettings.tokenKey] == "secret")
    }

    @Test func offlineKeepsOnlyTheKey() async throws {
        harness.spies.tracker.error = .rejected(0)
        try await harness.issues.saveToken("t")

        await harness.issues.load("ABC-2")
        await harness.issues.load("ABC-2")

        #expect(harness.issues.details["ABC-2"] == nil)
        #expect(harness.spies.tracker.calls == ["ABC-2"])
    }

    @Test func emptyTokenRemovesIt() async throws {
        try await harness.issues.saveToken("t")
        try await harness.issues.saveToken("")

        #expect(harness.issues.hasToken == false)
    }
}
