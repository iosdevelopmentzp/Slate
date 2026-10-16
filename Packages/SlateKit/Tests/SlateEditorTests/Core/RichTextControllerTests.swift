import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerTests {

    @Test func loadingShowsFormattedTextWithoutMarks() {
        let harness = EditorHarness(markdown: "# Trip\n\nSome **bold** text.\n")

        #expect(harness.text == "Trip\nSome bold text.")
        #expect(harness.font(at: 0)?.pointSize == 24)
        #expect(harness.font(at: 10)?.fontDescriptor.symbolicTraits.contains(.bold) == true)
        #expect(harness.markdown == "# Trip\n\nSome **bold** text.\n")
    }

    @Test func typingPublishesMarkdown() {
        let harness = EditorHarness(markdown: "Hello\n")
        harness.select(5)

        harness.type(" world")

        #expect(harness.markdown == "Hello world\n")
        #expect(harness.published.last == "Hello world\n")
    }

    @Test func returnContinuesAListAndAnEmptyItemEndsIt() {
        let harness = EditorHarness(markdown: "- one\n")
        harness.select(3)

        harness.type("\ntwo\n\nafter")

        #expect(harness.markdown == "- one\n- two\n\nafter\n")
    }

    @Test func returnAfterAHeadingStartsBodyText() {
        let harness = EditorHarness(markdown: "## Plan\n")
        harness.select(4)

        harness.type("\nfirst step")

        #expect(harness.markdown == "## Plan\n\nfirst step\n")
    }

    @Test func checklistContinuesUncheckedAndClickTogglesDone() {
        let harness = EditorHarness(markdown: "- [x] milk\n")
        harness.select(4)

        harness.type("\nbread")
        harness.controller.toggleCheckbox(at: 0)

        #expect(harness.markdown == "- [ ] milk\n- [ ] bread\n")
    }

    @Test func styleCommandsChangeTheParagraph() {
        let harness = EditorHarness(markdown: "Plan\n")
        harness.select(2)

        harness.controller.perform(.style(.heading))
        #expect(harness.markdown == "## Plan\n")

        harness.controller.perform(.list(.checklist))
        #expect(harness.markdown == "- [ ] Plan\n")

        harness.controller.perform(.list(.checklist))
        #expect(harness.markdown == "Plan\n")

        harness.controller.perform(.quote)
        #expect(harness.markdown == "> Plan\n")
    }

    @Test func boldTogglesOnTheSelectionAndUndoBringsItBack() {
        let harness = EditorHarness(markdown: "a word here\n")
        harness.selectText("word")

        harness.undoStep { harness.controller.perform(.inline(.bold)) }
        #expect(harness.markdown == "a **word** here\n")
        #expect(harness.commands.state.inline.contains(.bold))

        harness.undoStep { harness.controller.perform(.inline(.bold)) }
        #expect(harness.markdown == "a word here\n")

        harness.controller.undoManager.undo()
        harness.controller.textChanged()
        #expect(harness.markdown == "a **word** here\n")
    }

    @Test func boldWithoutASelectionAppliesToTheNextTyping() {
        let harness = EditorHarness(markdown: "a\n")
        harness.select(1)

        harness.controller.perform(.inline(.bold))
        harness.type(" b")

        #expect(harness.markdown == "a **b**\n")
    }

    @Test func tabIndentsAListItemUnderThePreviousOne() {
        let harness = EditorHarness(markdown: "- a\n- b\n")
        harness.caret(after: "b")

        harness.command(#selector(NSResponder.insertTab(_:)))
        #expect(harness.markdown == "- a\n  - b\n")

        harness.command(#selector(NSResponder.insertTab(_:)))
        #expect(harness.markdown == "- a\n  - b\n")

        harness.command(#selector(NSResponder.insertBacktab(_:)))
        #expect(harness.markdown == "- a\n- b\n")
    }

    @Test func backspaceAtTheStartOfAnItemMakesBodyText() {
        let harness = EditorHarness(markdown: "- a\n")
        harness.select(0)

        harness.command(#selector(NSResponder.deleteBackward(_:)))

        #expect(harness.markdown == "a\n")
    }

    @Test func numbersFollowTheOrder() {
        let harness = EditorHarness(markdown: "1. a\n2. b\n")
        harness.caret(after: "a")

        harness.type("\nnew")

        let numbers = [0, 2, 6].map { harness.controller.storage.attribute(.slateListNumber, at: $0, effectiveRange: nil) as? Int }
        #expect(numbers == [1, 2, 3])
        #expect(harness.markdown == "1. a\n2. new\n3. b\n")
    }

    @Test func monospacedKeepsLinesInOneBlockAndAnEmptyLineLeavesIt() {
        let harness = EditorHarness(markdown: "code\n")
        harness.select(4)
        harness.controller.perform(.style(.monospaced))

        harness.type("\nmore\n\nafter")

        #expect(harness.markdown == "```\ncode\nmore\n```\n\nafter\n")
    }

    @Test func typingADashAndSpaceStartsAList() {
        let harness = EditorHarness(markdown: "")

        harness.type("- milk\neggs")

        #expect(harness.markdown == "- milk\n- eggs\n")
    }

    @Test func imagesGoInTheirOwnParagraph() {
        let harness = EditorHarness(markdown: "First\n\nSecond\n")
        harness.caret(after: "Fir")

        harness.controller.insertMarkdownBlocks("![](../_attachments/a.png)\n")

        #expect(harness.markdown == "First\n\n![](../_attachments/a.png)\n\nSecond\n")
        #expect(harness.controller.storage.attribute(.attachment, at: 6, effectiveRange: nil) is ImageAttachment)
    }

    @Test func typingNextToAnImageMakesANewParagraph() {
        let harness = EditorHarness(markdown: "![](a.png)\n")
        harness.select(1)

        harness.type("note")

        #expect(harness.markdown == "![](a.png)\n\nnote\n")
    }

    @Test func backspaceAfterAnImageRemovesIt() {
        let harness = EditorHarness(markdown: "![](a.png)\n\ntext\n")
        harness.select(2)

        harness.command(#selector(NSResponder.deleteBackward(_:)))

        #expect(harness.markdown == "text\n")
    }

    @Test func aTableSurvivesAnEditElsewhere() {
        let table = "| a | b |\n|---|---|\n| 1 | 2 |"
        let harness = EditorHarness(markdown: "Intro\n\n\(table)\n")
        harness.select(5)

        harness.type("!")

        #expect(harness.markdown == "Intro!\n\n\(table)\n")
    }

    @Test func linkCommandAddsALinkToTheSelection() {
        let harness = EditorHarness(markdown: "see the map\n")
        harness.selectText("map")

        harness.controller.applyLink(.set("https://example.com/map"), to: harness.textView.selectedRange())

        #expect(harness.markdown == "see the [map](https://example.com/map)\n")
    }

    @Test func dividerIsInsertedAfterTheParagraph() {
        let harness = EditorHarness(markdown: "a\n")
        harness.select(1)

        harness.controller.perform(.divider)

        #expect(harness.markdown == "a\n\n---\n")
    }

    @Test func externalTextReplacesTheContent() {
        let harness = EditorHarness(markdown: "old\n")

        harness.controller.setMarkdown("- new\n")

        #expect(harness.text == "new")
        #expect(harness.block(at: 0).kind == .bullet)
    }

    @Test func copyWritesMarkdown() {
        let harness = EditorHarness(markdown: "a **b** c\n")
        harness.selectText("b c")
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("slate.test.copy"))

        #expect(harness.controller.copySelection(to: pasteboard))
        #expect(pasteboard.string(forType: PasteboardReader.markdownType) == "**b** c")
        #expect(pasteboard.string(forType: .string) == "b c")
    }

    @Test func theRoadmapScenarioWritesOnlyTheSubsetAndReadsBackTheSame() {
        let harness = EditorHarness(markdown: "")

        harness.controller.perform(.style(.title))
        harness.type("Trip\nPack ")
        harness.controller.perform(.inline(.bold))
        harness.type("light")
        harness.controller.perform(.inline(.bold))
        harness.type("\n")
        harness.controller.perform(.list(.checklist))
        harness.type("tickets")
        harness.controller.insertMarkdownBlocks("![](../_attachments/map.png)\n")

        let expected = "# Trip\n\nPack **light**\n\n- [ ] tickets\n\n![](../_attachments/map.png)\n"
        #expect(harness.markdown == expected)
        let reopened = EditorHarness(markdown: expected)
        #expect(harness.text.hasSuffix("\n"))
        #expect(reopened.text == String(harness.text.dropLast()))
        #expect(reopened.markdown == expected)
    }

    @Test func escapeGoesToTheWindow() {
        let harness = EditorHarness(markdown: "a\n")
        let window = EscapeWindow()
        window.contentView = harness.controller.scrollView

        harness.command(#selector(NSResponder.cancelOperation(_:)))

        #expect(window.cancelCount == 1)
    }
}

private final class EscapeWindow: NSWindow {
    var cancelCount = 0

    override func cancelOperation(_ sender: Any?) {
        cancelCount += 1
    }
}
