import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerTypedURLTests {

    @Test func aTypedAddressBecomesALinkAfterASpace() {
        let harness = EditorHarness(markdown: "go\n")
        harness.select(2)

        harness.type(" https://example.com/a. next")

        #expect(harness.controller.storage.attribute(.slateHref, at: 5, effectiveRange: nil) as? String == "https://example.com/a")
        #expect(harness.controller.storage.attribute(.slateHref, at: 3 + 21, effectiveRange: nil) == nil)
        #expect(harness.markdown == "go https://example.com/a. next\n")
    }

    @Test func aTypedAddressBecomesALinkOnReturn() {
        let harness = EditorHarness(markdown: "")

        harness.type("https://example.com/a\nnext")

        #expect(harness.controller.storage.attribute(.slateHref, at: 2, effectiveRange: nil) as? String == "https://example.com/a")
        #expect(harness.markdown == "https://example.com/a\n\nnext\n")
    }
}
