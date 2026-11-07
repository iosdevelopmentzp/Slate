import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerLinkHoverTests {
    private let markdown = "see [map](https://example.com/a) now\n\nplain text here\n"

    private func point(of needle: String, in harness: EditorHarness) throws -> CGPoint {
        let window = try #require(harness.textView.window)
        let range = (harness.text as NSString).range(of: needle)
        let screen = harness.textView.firstRect(forCharacterRange: NSRange(location: range.location + 1, length: 1), actualRange: nil)
        let rect = harness.textView.convert(window.convertFromScreen(screen), from: nil)
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    private func hover(_ harness: EditorHarness, at point: CGPoint?) async {
        harness.controller.hoverLink(at: point, after: .zero)
        await harness.controller.linkHoverTask?.value
    }

    @Test func hoverOnALinkShowsItsPreview() async throws {
        let harness = EditorHarness(markdown: markdown)

        try await hover(harness, at: point(of: "map", in: harness))

        let bar = harness.controller.linkBar
        #expect(bar.isHidden == false)
        #expect(bar.range == NSRange(location: 4, length: 3))
        #expect(bar.preview.titleText == "example.com")
    }

    @Test func aClickOnThePreviewOpensTheLink() async throws {
        let harness = EditorHarness(markdown: markdown)
        var opened: [EditorLink] = []
        harness.controller.handlers.openLink = { opened.append($0) }

        try await hover(harness, at: point(of: "map", in: harness))
        harness.controller.linkBar.preview.onOpen()

        #expect(opened == [.url("https://example.com/a")])
    }

    @Test func leavingTheLinkHidesThePreview() async throws {
        let harness = EditorHarness(markdown: markdown)
        harness.select(0)

        try await hover(harness, at: point(of: "map", in: harness))
        try await hover(harness, at: point(of: "plain", in: harness))

        #expect(harness.controller.linkBar.isHidden)
    }

    @Test func thePointerOnThePreviewKeepsIt() async throws {
        let harness = EditorHarness(markdown: markdown)

        try await hover(harness, at: point(of: "map", in: harness))
        let frame = harness.controller.linkBar.frame
        await hover(harness, at: CGPoint(x: frame.midX, y: frame.midY))

        #expect(harness.controller.linkBar.isHidden == false)
    }

    @Test func leavingTheLinkBringsBackThePreviewOfTheCaretLink() async throws {
        let harness = EditorHarness(markdown: "see [map](https://example.com/a) and [docs](https://example.com/docs)\n\nplain\n")
        harness.select(5)

        try await hover(harness, at: point(of: "docs", in: harness))
        #expect(harness.controller.linkBar.preview.titleText == "example.com")
        #expect(harness.controller.linkBar.range?.location == 12)
        try await hover(harness, at: point(of: "plain", in: harness))

        #expect(harness.controller.linkBar.range == NSRange(location: 4, length: 3))
    }
}
