import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerColorsTests {

    @Test func aHighlightOnTheSelectionIsWrittenWithEqualSigns() {
        let harness = EditorHarness(markdown: "Some important text\n")
        harness.selectText("important")

        harness.controller.perform(.highlight(.yellow))

        #expect(harness.markdown == "Some ==important== text\n")
        #expect(harness.commands.state.highlight == .yellow)
    }

    @Test func theSameHighlightAgainRemovesIt() {
        let harness = EditorHarness(markdown: "Some ==important== text\n")
        harness.selectText("important")

        harness.controller.perform(.highlight(.yellow))

        #expect(harness.markdown == "Some important text\n")
    }

    @Test func anotherHighlightReplacesTheFirst() {
        let harness = EditorHarness(markdown: "Some ==important== text\n")
        harness.selectText("important")

        harness.controller.perform(.highlight(.green))

        #expect(harness.markdown == "Some <mark style=\"background: #BBFABBA6;\">important</mark> text\n")
    }

    @Test func textColourAndHighlightCanBeTogether() {
        let harness = EditorHarness(markdown: "a b c\n")
        harness.selectText("b")

        harness.controller.perform(.textColor(.red))
        harness.controller.perform(.highlight(.yellow))

        #expect(harness.markdown == "a ==<span style=\"color: #E5484D;\">b</span>== c\n")
        harness.controller.perform(.textColor(nil))
        #expect(harness.markdown == "a ==b== c\n")
    }

    @Test func aHighlightShowsAsABackground() {
        let harness = EditorHarness(markdown: "a ==b== c\n")

        let background = harness.controller.storage.attribute(.backgroundColor, at: 2, effectiveRange: nil) as? NSColor

        #expect(background == HighlightColor.yellow.displayColor)
        #expect(harness.controller.storage.attribute(.backgroundColor, at: 0, effectiveRange: nil) == nil)
    }

    @Test func typingAfterChoosingAColourUsesIt() {
        let harness = EditorHarness(markdown: "a\n")
        harness.select(1)

        harness.controller.perform(.textColor(.blue))
        harness.type(" b")

        #expect(harness.markdown == "a <span style=\"color: #0090FF;\">b</span>\n")
    }

    @Test func aCodeBlockTakesNoColour() {
        let harness = EditorHarness(markdown: "```\nlet a = 1\n```\n")
        harness.selectText("let")

        harness.controller.perform(.highlight(.yellow))

        #expect(harness.markdown == "```\nlet a = 1\n```\n")
    }

    @Test func aTableCellTakesAHighlight() throws {
        let harness = EditorHarness(markdown: "| a b | c |\n|---|---|\n| 1 | 2 |\n")
        let view = try #require(harness.table()?.loadedView)
        view.beginEditing(TableCellIndex(row: 0, column: 0))
        view.cellEditor.setSelectedRange(NSRange(location: 2, length: 1))

        harness.controller.perform(.highlight(.pink))
        view.endEditing()

        #expect(harness.markdown == "| a <mark style=\"background: #FFB8EBA6;\">b</mark> | c |\n| --- | --- |\n| 1 | 2 |\n")
    }

    @Test func theMenuMarksTheCurrentColour() {
        let harness = EditorHarness(markdown: "a ==b== c\n")
        harness.selectText("b")
        let item = NSMenuItem(title: "Yellow", action: EditorMenuActions.highlight, keyEquivalent: "")
        item.tag = HighlightColor.yellow.rawValue
        let other = NSMenuItem(title: "Green", action: EditorMenuActions.highlight, keyEquivalent: "")
        other.tag = HighlightColor.green.rawValue

        #expect(harness.textView.validateUserInterfaceItem(item))
        #expect(item.state == .on)
        #expect(harness.textView.validateUserInterfaceItem(other))
        #expect(other.state == .off)
    }
}
