import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerBlockEdgesTests {
    @Test func upOnTheFirstLineOfACodeBlockOpensALineAbove() {
        let harness = EditorHarness(markdown: "```json\nURL\nvalue\n```\n")
        harness.select(1)

        harness.command(#selector(NSResponder.moveUp(_:)))
        harness.type("Intro")

        #expect(harness.markdown == "Intro\n\n```json\nURL\nvalue\n```\n")
    }

    @Test func leftAtTheStartOfAQuoteOpensALineAbove() {
        let harness = EditorHarness(markdown: "> quote\n\nText\n")
        harness.select(0)

        harness.command(#selector(NSResponder.moveLeft(_:)))
        harness.type("Intro")

        #expect(harness.markdown == "Intro\n\n> quote\n\nText\n")
    }

    @Test func upOnALaterLineOfTheCodeBlockOnlyMovesTheCaret() {
        let harness = EditorHarness(markdown: "```\nfirst\nsecond\n```\n")
        harness.caret(after: "sec")

        harness.command(#selector(NSResponder.moveUp(_:)))

        #expect(harness.markdown == "```\nfirst\nsecond\n```\n")
        #expect(harness.textView.selectedRange().location < (harness.text as NSString).range(of: "second").location)
    }

    @Test func downOnTheLastLineOfACodeBlockOpensALineBelow() {
        let harness = EditorHarness(markdown: "Text\n\n```\ncode\n```\n")
        harness.caret(after: "code")

        harness.command(#selector(NSResponder.moveDown(_:)))
        harness.type("After")

        #expect(harness.markdown == "Text\n\n```\ncode\n```\n\nAfter\n")
    }

    @Test func rightAtTheEndOfACodeBlockOpensALineBelow() {
        let harness = EditorHarness(markdown: "```\ncode\n```\n")
        harness.caret(after: "code")

        harness.command(#selector(NSResponder.moveRight(_:)))
        harness.type("After")

        #expect(harness.markdown == "```\ncode\n```\n\nAfter\n")
    }

    @Test func aBodyParagraphAtTheTopGetsNoNewLine() {
        let harness = EditorHarness(markdown: "Text\n\n```\ncode\n```\n")
        harness.select(0)

        harness.command(#selector(NSResponder.moveUp(_:)))

        #expect(harness.text == "Text\ncode")
    }
}
