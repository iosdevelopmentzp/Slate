import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerOutlineTests {

    @Test func theMenuListsHeadingsAndMarksTheCurrentOne() {
        let harness = EditorHarness(markdown: "## Context\n\nText\n\n### Detail\n\n## Log\n\nend\n")
        harness.caret(after: "Text")

        let menu = harness.controller.outlineMenu()

        #expect(menu.items.map(\.title) == ["Context", "Detail", "Log"])
        #expect(menu.items.map(\.indentationLevel) == [0, 1, 0])
        #expect(menu.items.filter { $0.state == .on }.map(\.title) == ["Context"])
    }

    @Test func choosingAHeadingMovesTheCaretThere() throws {
        let harness = EditorHarness(markdown: "## Context\n\nText\n\n## Log\n\nend\n")
        let item = try #require(harness.controller.outlineMenu().items.last)

        harness.textView.slateJumpToHeading(item)

        #expect(harness.textView.selectedRange() == NSRange(location: (harness.text as NSString).range(of: "Log").location, length: 0))
    }

    @Test func aNoteWithoutHeadingsSaysSo() {
        let harness = EditorHarness(markdown: "plain\n")

        let menu = harness.controller.outlineMenu()

        #expect(menu.items.map(\.title) == ["No headings in this note"])
        #expect(menu.items.first?.isEnabled == false)
    }

    @Test func aFocusRequestWithAHeadingPutsTheCaretOnIt() async {
        let harness = EditorHarness(markdown: "# Title\n\n## Plan\n\nText\n\n## Log\n\nMore\n")

        harness.controller.apply(focus: EditorFocusRequest(token: 1, heading: "log"))
        await Task.yield()
        await Task.yield()

        #expect(harness.textView.selectedRange().location == (harness.text as NSString).range(of: "Log").location)
    }
}
