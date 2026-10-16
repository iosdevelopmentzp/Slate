import AppKit
import Testing
@testable import SlateEditor

@Suite struct EditorControllerTests {
    @Test func enterContinuesTheListInTheView() {
        let harness = EditorHarness(text: "- one")
        harness.textView.setSelectedRange(NSRange(location: 5, length: 0))

        harness.textView.insertNewline(nil)

        #expect(harness.controller.text == "- one\n- ")
        #expect(harness.textView.selectedRange() == NSRange(location: 8, length: 0))
    }

    @Test func enterInsideCodeIsAPlainNewline() {
        let harness = EditorHarness(text: "```\n- one\n```")
        harness.textView.setSelectedRange(NSRange(location: 9, length: 0))

        harness.textView.insertNewline(nil)

        #expect(harness.controller.text == "```\n- one\n\n```")
    }

    @Test func tabInsideCodeInsertsFourSpaces() {
        let harness = EditorHarness(text: "```\nx\n```")
        harness.textView.setSelectedRange(NSRange(location: 4, length: 0))

        harness.textView.insertTab(nil)

        #expect(harness.controller.text == "```\n    x\n```")
    }

    @Test func insertionLandsOnItsOwnLine() {
        let harness = EditorHarness(text: "before after")
        harness.textView.setSelectedRange(NSRange(location: 6, length: 0))

        harness.controller.apply(insertion: EditorInsertion(token: 1, markdown: "![](a.png)"))
        harness.controller.apply(insertion: EditorInsertion(token: 1, markdown: "![](a.png)"))

        #expect(harness.controller.text == "before\n![](a.png)\n after")
    }

    @Test func linkUnderTheCaretIsFound() {
        let harness = EditorHarness(text: "see [[Other note]] and https://example.com")

        #expect(harness.controller.link(at: 8) == .wiki("Other note"))
        #expect(harness.controller.link(at: 30) == .url("https://example.com"))
        #expect(harness.controller.link(at: 1) == nil)
    }

    @Test func codeBlockContentExcludesTheFences() throws {
        let harness = EditorHarness(text: "a\n```swift\nlet x = 1\nlet y = 2\n```\nb")

        let block = try #require(harness.controller.codeBlock(containingLine: 2))

        #expect(block.open == 1)
        #expect(harness.controller.nsText.substring(with: block.content) == "let x = 1\nlet y = 2")
    }

    @Test func toggleLineCyclesTheCheckbox() {
        let harness = EditorHarness(text: "buy milk")
        harness.textView.setSelectedRange(NSRange(location: 3, length: 0))

        harness.controller.toggleCurrentLine()
        harness.controller.toggleCurrentLine()

        #expect(harness.controller.text == "- [x] buy milk")
    }

    @Test func wrapMakesTheSelectionBold() {
        let harness = EditorHarness(text: "make bold")
        harness.textView.setSelectedRange(NSRange(location: 5, length: 4))

        harness.controller.wrap(with: "**")

        #expect(harness.controller.text == "make **bold**")
    }

    @Test func undoRevertsAListContinuation() {
        let harness = EditorHarness(text: "- one")
        harness.textView.setSelectedRange(NSRange(location: 5, length: 0))
        harness.textView.insertNewline(nil)

        harness.textView.undoManager?.undo()

        #expect(harness.controller.text == "- one")
    }

    @Test func settingNewTextClearsUndo() {
        let harness = EditorHarness(text: "- [ ] a")
        harness.controller.toggleCheckbox(lineAt: 0)

        harness.controller.setText("other")

        #expect(harness.textView.undoManager?.canUndo == false)
    }

    @Test func enterAfterAnOpeningFenceAddsTheClosingOne() {
        let harness = EditorHarness(text: "```swift")
        harness.textView.setSelectedRange(NSRange(location: 8, length: 0))

        harness.textView.insertNewline(nil)

        #expect(harness.controller.text == "```swift\n\n```")
        #expect(harness.textView.selectedRange() == NSRange(location: 9, length: 0))
    }

    @Test func enterInsideAClosedFenceIsPlain() {
        let harness = EditorHarness(text: "```\nx\n```")
        harness.textView.setSelectedRange(NSRange(location: 3, length: 0))

        harness.textView.insertNewline(nil)

        #expect(harness.controller.text == "```\n\nx\n```")
    }

    @Test func toggleCommentWorksOnlyInCode() {
        let harness = EditorHarness(text: "```yaml\nkey: 1\n```\nprose")
        harness.textView.setSelectedRange(NSRange(location: 9, length: 0))

        harness.controller.toggleComment()
        harness.textView.setSelectedRange(NSRange(location: 22, length: 0))
        harness.controller.toggleComment()

        #expect(harness.controller.text == "```yaml\n# key: 1\n```\nprose")
    }

    @Test func typingABacktickAddsAPair() {
        let harness = EditorHarness(text: "a ")
        harness.textView.setSelectedRange(NSRange(location: 2, length: 0))

        harness.textView.insertText("`", replacementRange: NSRange(location: NSNotFound, length: 0))

        #expect(harness.controller.text == "a ``")
    }
}
