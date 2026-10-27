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

        harness.textView.undo(nil)
        #expect(harness.markdown == "a **word** here\n")

        harness.textView.redo(nil)
        #expect(harness.markdown == "a word here\n")
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

        harness.controller.applyLink(.set(text: nil, href: "https://example.com/map"), to: harness.textView.selectedRange())

        #expect(harness.markdown == "see the [map](https://example.com/map)\n")
    }

    @Test func savingNewTextChangesTheTextOfTheLink() {
        let harness = EditorHarness(markdown: "see [map](https://example.com) now\n")
        harness.select(5)

        let range = harness.controller.linkRange(at: 5) ?? NSRange()
        harness.controller.applyLink(.set(text: "the map", href: "https://example.com/b"), to: range)

        #expect(harness.markdown == "see [the map](https://example.com/b) now\n")
    }

    @Test func aNoteLinkWithOtherTextIsWrittenWithAnAlias() {
        let harness = EditorHarness(markdown: "see it\n")
        harness.selectText("it")

        harness.controller.applyLink(.set(text: "that note", href: "wiki:Other"), to: harness.textView.selectedRange())

        #expect(harness.markdown == "see [[Other|that note]]\n")
    }

    @Test func aLinkWithoutSelectionInsertsItsText() {
        let harness = EditorHarness(markdown: "see , now\n")
        harness.select(4)

        harness.controller.applyLink(.set(text: "Other", href: "wiki:Other"), to: harness.textView.selectedRange())

        #expect(harness.markdown == "see [[Other]], now\n")
    }

    @Test func theCaretInALinkShowsTheLinkBarAndRemoveTakesTheLinkAway() {
        let harness = EditorHarness(markdown: "see [map](https://example.com) now\n")
        harness.select(5)

        #expect(harness.controller.linkBar.isHidden == false)
        let range = harness.controller.linkBar.range ?? NSRange()
        harness.controller.performLinkAction(.remove, range: range)

        #expect(harness.markdown == "see map now\n")
        #expect(harness.controller.linkBar.isHidden)
    }

    @Test func theMenuOfALinkStartsWithTheLinkActions() {
        let harness = EditorHarness(markdown: "see [map](https://example.com) now\n")

        let menu = harness.controller.linkMenu(at: 5, adding: NSMenu())

        #expect(menu?.items.prefix(4).map(\.title) == ["Open Link", "Edit Link…", "Copy Link Address", "Remove Link"])
        #expect(harness.controller.linkMenu(at: 1, adding: NSMenu()) == nil)
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

    @Test func anImageAddedInAListItemGoesUnderTheItemAndTheNumbersGoOn() {
        let harness = EditorHarness(markdown: "1. First\n2. Second\n")
        harness.selectText("First")

        harness.controller.insertMarkdownBlocks("![](a.png)\n")

        #expect(harness.markdown == "1. First\n\n   ![](a.png)\n\n2. Second\n")
    }

    @Test func returnAfterAnImageInAListStartsTheNextItem() {
        let harness = EditorHarness(markdown: "1. First\n\n   ![](a.png)\n")
        let image = (harness.text as NSString).range(of: RichText.attachmentString)
        harness.controller.textView.setSelectedRange(NSRange(location: NSMaxRange(image), length: 0))

        harness.type("\nSecond")

        #expect(harness.markdown == "1. First\n\n   ![](a.png)\n\n2. Second\n")
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

        let expected = "# Trip\n\nPack **light**\n\n- [ ] tickets\n\n  ![](../_attachments/map.png)\n"
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

    @Test func theUndoMenuItemsFollowTheEditorHistory() {
        let harness = EditorHarness(markdown: "a\n")
        harness.select(1)
        let undo = NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        #expect(harness.textView.validateUserInterfaceItem(undo) == false)

        harness.undoStep { harness.type("b") }
        #expect(harness.textView.validateUserInterfaceItem(undo))

        harness.textView.undo(nil)
        #expect(harness.markdown == "a\n")
        #expect(harness.textView.validateUserInterfaceItem(redo))

        harness.textView.redo(nil)
        #expect(harness.markdown == "ab\n")
    }

    @Test func undoGoesThroughTheResponderChainToTheEditor() {
        let harness = EditorHarness(markdown: "a\n")
        harness.select(1)
        harness.undoStep { harness.type("b") }

        let handled = harness.textView.tryToPerform(Selector(("undo:")), with: nil)

        #expect(handled)
        #expect(harness.markdown == "a\n")
    }
}

private final class EscapeWindow: NSWindow {
    var cancelCount = 0

    override func cancelOperation(_ sender: Any?) {
        cancelCount += 1
    }

    @Test func theTextHasRoomBelowItsLastLine() throws {
        let harness = EditorHarness(markdown: (1...40).map { "Line \($0)" }.joined(separator: "\n\n") + "\n")
        let layout = try #require(harness.textView.textLayoutManager)
        layout.ensureLayout(for: layout.documentRange)
        harness.textView.scrollToEndOfDocument(nil)
        harness.layout()

        let bottom = layout.usageBoundsForTextContainer.maxY + harness.textView.textContainerOrigin.y

        #expect(harness.textView.textContainerOrigin.y == RichTextEditorView.topMargin)
        #expect(harness.textView.frame.height - bottom >= RichTextEditorView.bottomMargin - 1)
    }
}
