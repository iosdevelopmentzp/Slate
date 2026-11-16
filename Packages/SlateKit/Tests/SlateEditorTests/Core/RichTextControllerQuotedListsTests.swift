import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerQuotedListsTests {
    @Test func returnContinuesAListInAQuoteAndAnEmptyItemGoesBackToTheQuote() {
        let harness = EditorHarness(markdown: "> Known\n>\n> - one\n")
        harness.select(9)

        harness.type("\ntwo\n\nend")
        harness.controller.flush()

        #expect(harness.markdown == "> Known\n>\n> - one\n> - two\n>\n> end\n")
    }

    @Test func backspaceAtTheStartOfAQuotedItemMakesQuoteText() {
        let harness = EditorHarness(markdown: "> Known\n>\n> - one\n")
        harness.select(6)

        harness.command(#selector(NSResponder.deleteBackward(_:)))
        harness.controller.flush()

        #expect(harness.markdown == "> Known\n>\n> one\n")
    }

    @Test func typingADashAndSpaceInAQuoteStartsAQuotedList() {
        let harness = EditorHarness(markdown: "> Known\n")
        harness.select(5)

        harness.type("\n- one\ntwo")
        harness.controller.flush()

        #expect(harness.markdown == "> Known\n>\n> - one\n> - two\n")
    }
}
