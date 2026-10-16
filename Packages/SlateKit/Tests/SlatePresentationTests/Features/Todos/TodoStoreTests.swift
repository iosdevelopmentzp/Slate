import Foundation
import SlateDomain
import SlateMocks
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct TodoStoreTests {
    private let harness = StoreHarness()

    private func seed() async throws {
        harness.seed("Tasks/A.md", id: "a", title: "A", body: "- [ ] one\n- [x] done")
        harness.seed("Notes/B.md", id: "b", title: "B", body: "- [ ] two")
        try await harness.index()
        await harness.noteList.refresh()
    }

    @Test func openItemsAreGroupedByNote() async throws {
        try await seed()

        await harness.todos.refresh()

        #expect(harness.todos.items.count == 2)
        #expect(Set(harness.todos.groups.map(\.title)) == ["A", "B"])
    }

    @Test func toggleWritesTheFileAndTellsTheEditor() async throws {
        try await seed()
        await harness.todos.refresh()
        let item = try #require(harness.todos.items.first { $0.text == "one" })
        harness.clearPosted()

        await harness.todos.toggle(item)

        #expect(harness.spies.files.text(at: VaultPath(rawValue: "Tasks/A.md"))?.hasSuffix("- [x] one\n- [x] done") == true)
        #expect(harness.posted.contains(.vaultChanged([VaultPath(rawValue: "Tasks/A.md")])))
        #expect(harness.todos.items.contains(item) == false)
    }

    @Test func groupingByTicketIsRemembered() async throws {
        try await seed()
        await harness.todos.refresh()

        harness.todos.groupsByTicket = true

        #expect(harness.todos.groups.map(\.title) == ["No ticket"])
        #expect(harness.keyValues.bool(forKey: "todos.byTicket"))
    }
}
