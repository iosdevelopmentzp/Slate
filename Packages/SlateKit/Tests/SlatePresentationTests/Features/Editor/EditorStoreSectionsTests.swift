import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct EditorStoreSectionsTests {
    private let harness = StoreHarness()

    private func open(_ path: String, id: String) async throws {
        let vaultPath = harness.seed(path, id: id, title: nil, body: "## Context\n\nText\n")
        try await harness.index()
        let summary = try #require(try await harness.ports.index.summaries(space: nil).first { $0.path == vaultPath })
        harness.navigator.select(summary.id)
        await harness.editor.open(summary.id)
    }

    @Test func collapsedSectionsAreRememberedPerNote() async throws {
        try await open("Inbox/A.md", id: "a")
        harness.editor.setCollapsedSections(["1 Context"])

        try await open("Inbox/B.md", id: "b")
        #expect(harness.editor.collapsedSections == [])

        try await open("Inbox/A.md", id: "a")
        #expect(harness.editor.collapsedSections == ["1 Context"])
    }
}
