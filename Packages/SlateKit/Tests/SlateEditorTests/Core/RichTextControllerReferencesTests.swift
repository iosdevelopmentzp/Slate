import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerReferencesTests {
    @Test func aReferenceLooksLikeALinkButStaysPlainText() {
        let harness = EditorHarness(markdown: "Fix ABC-123 now\n", configuration: EditorConfiguration(references: [.tickets]))

        #expect(harness.controller.reference(at: 5) == .ticket("ABC-123"))
        #expect(harness.controller.reference(at: 1) == nil)
        harness.controller.flush()
        #expect(harness.markdown == "Fix ABC-123 now\n")
    }

    @Test func openingAReferenceGoesToTheHost() {
        let harness = EditorHarness(markdown: "See File.swift:3\n", configuration: EditorConfiguration(references: [.files]))
        var opened: [EditorLink] = []
        harness.controller.handlers.openLink = { opened.append($0) }

        #expect(harness.controller.openLink(at: 6))
        #expect(opened == [.reference(.file(path: "File.swift", line: 3))])
    }

    @Test func withoutKindsNothingIsMarked() {
        let harness = EditorHarness(markdown: "Fix ABC-123 now\n")

        #expect(harness.controller.reference(at: 5) == nil)
    }
}
