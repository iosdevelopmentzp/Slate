import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct EditorCommandsTests {
    @Test func findIfFocusedFindsInTheNoteWhenTheTextHasFocus() {
        let harness = EditorHarness(markdown: "Text\n")

        #expect(harness.controller.isFocused)
        #expect(harness.commands.findIfFocused())
    }

    @Test func findIfFocusedLeavesTheSearchToTheAppElsewhere() {
        let harness = EditorHarness(markdown: "Text\n")
        harness.window.makeFirstResponder(nil)

        #expect(harness.controller.isFocused == false)
        #expect(harness.commands.findIfFocused() == false)
    }
}
