import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerCopyExportTests {
    @Test func withoutASelectionTheWholeNoteIsCopiedForJira() {
        let harness = EditorHarness(markdown: "# Plan\n\nDo **it**.\n")
        let board = NSPasteboard.withUniqueName()

        harness.controller.copy(for: .jira, to: board)

        #expect(board.string(forType: .string) == "h1. Plan\n\nDo *it*.")
    }

    @Test func theSelectionIsCopiedForSlackAsHTMLAndText() {
        let harness = EditorHarness(markdown: "first line\n\nsecond **line**\n")
        harness.selectText("second line")
        let board = NSPasteboard.withUniqueName()

        harness.controller.copy(for: .slack, to: board)

        #expect(board.string(forType: .string) == "second *line*")
        #expect(board.string(forType: .html) == "<p>second <b>line</b></p>")
    }
}
