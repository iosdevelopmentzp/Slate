import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerCalloutTests {
    @Test func aParagraphBecomesACalloutWithAnEmptyTitle() {
        let harness = EditorHarness(markdown: "Before\n\nAsk the team\n")
        harness.selectText("Ask")

        harness.controller.perform(.callout("QUESTION"))
        harness.controller.flush()

        #expect(harness.markdown == "Before\n\n> [!QUESTION]\n> Ask the team\n")
    }

    @Test func choosingAnotherKindChangesTheWholeCallout() {
        let harness = EditorHarness(markdown: "> [!NOTE] Title\n> one\n>\n> two\n")
        harness.selectText("two")

        harness.controller.perform(.callout("WARNING"))
        harness.controller.flush()

        #expect(harness.markdown == "> [!WARNING] Title\n> one\n>\n> two\n")
    }

    @Test func returnInTheTitleStartsTheBody() {
        let harness = EditorHarness(markdown: "> [!TIP] Title\n> body\n")
        harness.selectText("Title")
        harness.select(5)

        harness.type("\nfirst")
        harness.controller.flush()

        #expect(harness.markdown == "> [!TIP] Title\n> first\n>\n> body\n")
    }
}
