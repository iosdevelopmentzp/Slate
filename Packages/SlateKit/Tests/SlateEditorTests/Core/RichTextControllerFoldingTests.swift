import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerFoldingTests {
    private let markdown = "## Context\n\nText\n\n### Detail\n\nMore\n\n## Log\n\nend\n"

    private func location(of needle: String, in harness: EditorHarness) -> Int {
        (harness.text as NSString).range(of: needle).location
    }

    private func visibleParagraphs(_ harness: EditorHarness) -> [String] {
        guard let layout = harness.textView.textLayoutManager else { return [] }
        var paragraphs: [String] = []
        layout.enumerateTextLayoutFragments(from: layout.documentRange.location, options: [.ensuresLayout]) { fragment in
            let start = layout.offset(from: layout.documentRange.location, to: fragment.rangeInElement.location)
            let end = layout.offset(from: layout.documentRange.location, to: fragment.rangeInElement.endLocation)
            let text = (harness.text as NSString).substring(with: NSRange(location: start, length: end - start))
            paragraphs.append(text.trimmingCharacters(in: .newlines))
            return true
        }
        return paragraphs
    }

    private func click(_ harness: EditorHarness, heading: Int) throws -> NSEvent {
        let layout = try #require(harness.textView.textLayoutManager)
        let start = try #require(layout.location(layout.documentRange.location, offsetBy: heading))
        let frame = try #require(layout.textLayoutFragment(for: start)).layoutFragmentFrame
        let origin = harness.textView.textContainerOrigin
        let line = CGPoint(x: origin.x + 20, y: origin.y + frame.midY)
        harness.controller.hoverHeading(at: line)
        let fragment = try #require(layout.textLayoutFragment(for: start) as? RichLayoutFragment)
        let mark = fragment.foldRect.offsetBy(dx: origin.x + fragment.layoutFragmentFrame.minX, dy: origin.y + fragment.layoutFragmentFrame.minY)
        let point = harness.textView.convert(CGPoint(x: mark.midX, y: mark.midY), to: nil)
        return try #require(NSEvent.mouseEvent(with: .leftMouseDown, location: point, modifierFlags: [], timestamp: 0, windowNumber: harness.window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
    }

    @Test func collapsingAHeadingHidesItsSectionButKeepsTheText() {
        let harness = EditorHarness(markdown: markdown)

        harness.controller.toggleSection(at: 0)
        harness.layout()

        #expect(visibleParagraphs(harness) == ["Context", "Log", "end"])
        #expect(harness.markdown == markdown)
    }

    @Test func expandingShowsTheSectionAgain() {
        let harness = EditorHarness(markdown: markdown)

        harness.controller.toggleSection(at: 0)
        harness.controller.toggleSection(at: 0)
        harness.layout()

        #expect(visibleParagraphs(harness) == ["Context", "Text", "Detail", "More", "Log", "end"])
    }

    @Test func aClickOnTheArrowCollapsesAndExpands() throws {
        let harness = EditorHarness(markdown: markdown)

        #expect(harness.controller.handleMouseDown(try click(harness, heading: 0)))
        harness.layout()
        #expect(visibleParagraphs(harness) == ["Context", "Log", "end"])

        #expect(harness.controller.handleMouseDown(try click(harness, heading: 0)))
        harness.layout()
        #expect(visibleParagraphs(harness) == ["Context", "Text", "Detail", "More", "Log", "end"])
    }

    @Test func theArrowShowsOnHoverAndStaysWhenCollapsed() throws {
        let harness = EditorHarness(markdown: markdown)
        let layout = try #require(harness.textView.textLayoutManager)
        let start = try #require(layout.location(layout.documentRange.location, offsetBy: 0))

        #expect((layout.textLayoutFragment(for: start) as? RichLayoutFragment)?.fold == nil)
        #expect(harness.controller.foldHit(at: CGPoint(x: 10, y: 20)) == nil)
        _ = try click(harness, heading: 0)
        #expect((layout.textLayoutFragment(for: start) as? RichLayoutFragment)?.fold == .open)

        harness.controller.toggleSection(at: 0)
        harness.controller.hoverHeading(at: nil)
        harness.layout()
        #expect((layout.textLayoutFragment(for: start) as? RichLayoutFragment)?.fold == .closed)
    }

    @Test func theCommandCollapsesTheSectionOfTheCaretAndMovesTheCaretToItsHeading() {
        let harness = EditorHarness(markdown: markdown)
        harness.caret(after: "More")

        harness.controller.perform(.collapseSection)
        harness.layout()

        #expect(visibleParagraphs(harness) == ["Context", "Text", "Detail", "Log", "end"])
        #expect(harness.textView.selectedRange() == NSRange(location: NSMaxRange((harness.text as NSString).range(of: "Detail")), length: 0))
    }

    @Test func expandSectionAlsoOpensTheSectionsInside() {
        let harness = EditorHarness(markdown: markdown)
        harness.controller.perform(.collapseAllSections)
        harness.layout()
        #expect(visibleParagraphs(harness) == ["Context", "Log"])

        harness.caret(after: "Context")
        harness.controller.perform(.expandSection)
        harness.layout()
        #expect(visibleParagraphs(harness) == ["Context", "Text", "Detail", "More", "Log"])

        harness.controller.perform(.expandAllSections)
        harness.layout()
        #expect(visibleParagraphs(harness) == ["Context", "Text", "Detail", "More", "Log", "end"])
    }

    @Test func theCaretSkipsTheHiddenText() {
        let harness = EditorHarness(markdown: markdown)
        harness.controller.toggleSection(at: 0)
        harness.caret(after: "Context")

        harness.command(#selector(NSResponder.moveRight(_:)))
        #expect(harness.textView.selectedRange().location == location(of: "Log", in: harness))

        harness.command(#selector(NSResponder.moveLeft(_:)))
        #expect(harness.textView.selectedRange().location == NSMaxRange((harness.text as NSString).range(of: "Context")))
    }

    @Test func aNewLineAfterACollapsedHeadingExpandsIt() {
        let harness = EditorHarness(markdown: markdown)
        harness.controller.toggleSection(at: 0)
        harness.caret(after: "Context")

        harness.type("\nnew")

        #expect(visibleParagraphs(harness).contains("Text"))
        #expect(visibleParagraphs(harness).contains("new"))
    }

    @Test func editsAboveACollapsedHeadingKeepItCollapsed() {
        let harness = EditorHarness(markdown: markdown)
        let log = location(of: "Log", in: harness)
        harness.controller.toggleSection(at: log)
        harness.caret(after: "Text")

        harness.type("s")

        #expect(visibleParagraphs(harness) == ["Context", "Texts", "Detail", "More", "Log"])
    }

    @Test func findingHiddenTextExpandsItsSection() {
        let harness = EditorHarness(markdown: markdown)
        harness.controller.toggleSection(at: 0)

        harness.selectText("More")
        harness.layout()

        #expect(visibleParagraphs(harness).contains("More"))
        #expect(harness.textView.selectedRange() == (harness.text as NSString).range(of: "More"))
    }

    @Test func turningTheHeadingIntoBodyTextShowsTheSection() {
        let harness = EditorHarness(markdown: markdown)
        harness.controller.toggleSection(at: 0)
        harness.caret(after: "Context")

        harness.controller.perform(.style(.body))
        harness.layout()

        #expect(visibleParagraphs(harness) == ["Context", "Text", "Detail", "More", "Log", "end"])
    }

    @Test func aHeadingWithoutTextBelowCannotCollapse() {
        let harness = EditorHarness(markdown: "## One\n\n## Two\n\nend\n")

        harness.controller.toggleSection(at: 0)
        harness.layout()

        #expect(visibleParagraphs(harness) == ["One", "Two", "end"])
    }

    @Test func collapsingReportsTheSectionsAndApplyingRestoresThem() {
        let harness = EditorHarness(markdown: markdown)
        var reported: [[String]] = []
        harness.controller.handlers.collapsedSections = { reported.append($0) }

        harness.controller.toggleSection(at: location(of: "Detail", in: harness))
        harness.controller.toggleSection(at: location(of: "Detail", in: harness))
        #expect(reported == [["2 Detail"], []])

        harness.controller.setMarkdown("## Other\n\nx\n")
        harness.controller.setMarkdown(markdown)
        harness.controller.apply(collapsedSections: ["1 Context"])
        harness.layout()
        #expect(visibleParagraphs(harness) == ["Context", "Log", "end"])
        #expect(reported == [["2 Detail"], []])
    }

    @Test func renamingACollapsedHeadingReportsTheNewKey() {
        let harness = EditorHarness(markdown: markdown)
        var reported: [[String]] = []
        harness.controller.handlers.collapsedSections = { reported.append($0) }
        harness.controller.toggleSection(at: 0)
        harness.caret(after: "Context")

        harness.type("s")

        #expect(reported.last == ["1 Contexts"])
    }
}
