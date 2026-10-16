import AppKit
import Testing
@testable import SlateEditor

@Suite struct EditorRenderingTests {
    @Test func headingIsLargerThanProse() {
        let harness = EditorHarness(text: "# Title\nplain")

        let heading = try! #require(harness.font(at: 0))
        let prose = try! #require(harness.font(at: 8))
        #expect(heading.pointSize > prose.pointSize)
    }

    @Test func openingAFenceAboveRestylesTheLinesBelow() async throws {
        let harness = EditorHarness(text: "a\nplain line\nmore")

        harness.type("```\n", at: 0)

        try await waitForMainActor()
        let font = try #require(harness.font(at: 6))
        #expect(font.isFixedPitch)
    }

    @Test func checkboxClickWritesAnX() {
        let harness = EditorHarness(text: "- [ ] task")

        harness.controller.toggleCheckbox(lineAt: 0)

        #expect(harness.controller.text == "- [x] task")
    }

    @Test func undoRestoresTheCheckbox() {
        let harness = EditorHarness(text: "- [ ] task")

        harness.controller.toggleCheckbox(lineAt: 0)
        harness.textView.undoManager?.undo()

        #expect(harness.controller.text == "- [ ] task")
    }

    private func waitForMainActor() async throws {
        for _ in 0..<5 { await Task.yield() }
    }
}
