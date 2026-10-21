import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerSearchMatchesTests {
    private func highlighted(_ harness: EditorHarness) -> [NSRange] {
        guard let layout = harness.textView.textLayoutManager else { return [] }
        var ranges: [NSRange] = []
        layout.enumerateRenderingAttributes(from: layout.documentRange.location, reverse: false) { _, attributes, range in
            if attributes[.backgroundColor] != nil {
                let start = layout.offset(from: layout.documentRange.location, to: range.location)
                ranges.append(NSRange(location: start, length: layout.offset(from: range.location, to: range.endLocation)))
            }
            return true
        }
        return ranges
    }

    @Test func openingFromSearchHighlightsEveryMatch() {
        let harness = EditorHarness(markdown: "Simulator on a branch\n\nAnother simulator, and the Branch again\n")
        let text = harness.text as NSString

        harness.controller.apply(focus: EditorFocusRequest(token: 1, words: ["simulator", "branch", "a"]))

        let expected = [
            text.range(of: "Simulator"),
            text.range(of: "branch"),
            text.range(of: "simulator"),
            text.range(of: "Branch"),
        ]
        #expect(harness.controller.matchHighlights == expected)
        #expect(highlighted(harness) == expected)
    }

    @Test func aFocusWithoutWordsHighlightsNothing() {
        let harness = EditorHarness(markdown: "Simulator\n")

        harness.controller.apply(focus: EditorFocusRequest(token: 1, atStart: true, words: ["simulator"]))

        #expect(harness.controller.matchHighlights.isEmpty)
    }

    @Test func typingRemovesTheHighlights() {
        let harness = EditorHarness(markdown: "Simulator on a branch\n")
        harness.controller.apply(focus: EditorFocusRequest(token: 1, words: ["branch"]))
        harness.select(0)

        harness.type("x")

        #expect(harness.controller.matchHighlights.isEmpty)
        #expect(highlighted(harness).isEmpty)
    }

    @Test func escapeRemovesTheHighlightsFirst() {
        let harness = EditorHarness(markdown: "Simulator on a branch\n")
        harness.controller.apply(focus: EditorFocusRequest(token: 1, words: ["branch"]))

        harness.command(#selector(NSResponder.cancelOperation(_:)))

        #expect(harness.controller.matchHighlights.isEmpty)
        #expect(highlighted(harness).isEmpty)
    }

    @Test func anotherNoteHasNoHighlights() {
        let harness = EditorHarness(markdown: "Simulator on a branch\n")
        harness.controller.apply(focus: EditorFocusRequest(token: 1, words: ["branch"]))

        harness.controller.setMarkdown("Other branch\n")

        #expect(harness.controller.matchHighlights.isEmpty)
    }
}
