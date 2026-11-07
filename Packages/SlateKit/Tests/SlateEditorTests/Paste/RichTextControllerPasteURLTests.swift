import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerPasteURLTests {
    private func pasteboard(_ text: String) -> NSPasteboard {
        let board = NSPasteboard.withUniqueName()
        board.declareTypes([.string], owner: nil)
        board.setString(text, forType: .string)
        return board
    }

    @Test func anAddressPastedOnSelectedTextLinksThatText() {
        let harness = EditorHarness(markdown: "see the ticket now\n")
        harness.selectText("the ticket")

        harness.controller.paste(from: pasteboard("https://example.com/t/1"))

        #expect(harness.markdown == "see [the ticket](https://example.com/t/1) now\n")
    }

    @Test func aKnownAddressIsPastedWithAShortName() {
        let harness = EditorHarness(markdown: "see , ok\n")
        harness.select(4)

        harness.controller.paste(from: pasteboard("https://example.atlassian.net/browse/ABC-123\n"))

        #expect(harness.markdown == "see [ABC-123](https://example.atlassian.net/browse/ABC-123), ok\n")
    }

    @Test func anOtherAddressIsPastedAsALinkThatStaysBareInTheFile() {
        let harness = EditorHarness(markdown: "see , ok\n")
        harness.select(4)

        harness.controller.paste(from: pasteboard("https://example.com/docs"))

        #expect(harness.markdown == "see https://example.com/docs, ok\n")
        #expect(harness.controller.storage.attribute(.slateHref, at: 6, effectiveRange: nil) as? String == "https://example.com/docs")
    }

    @Test func anAddressInACodeBlockStaysText() {
        let harness = EditorHarness(markdown: "```\nx\n```\n")
        harness.select(1)

        harness.controller.paste(from: pasteboard("https://example.com/docs"))

        #expect(harness.controller.storage.attribute(.slateHref, at: 2, effectiveRange: nil) == nil)
    }
}
