import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerTailMarkerTests {

    @Test func aNewEmptyBulletAtTheEndShowsItsMarker() {
        let harness = EditorHarness(markdown: "- one\n")
        harness.select(3)

        harness.type("\n")

        #expect(harness.controller.tailMarker.isHidden == false)
        #expect(harness.controller.tailMarker.decoration == .bullet(level: 0))
        #expect(harness.controller.tailMarker.superview === harness.textView)
    }

    @Test func theMarkerSitsLeftOfTheCaretOnTheNewLine() throws {
        let harness = EditorHarness(markdown: "- one\n")
        harness.select(3)

        harness.type("\n")

        let marker = harness.controller.tailMarker
        let rect = marker.markerRect.offsetBy(dx: marker.frame.minX, dy: marker.frame.minY)
        let caret = try #require(endCaret(in: harness))
        #expect(rect.maxX <= caret.minX)
        #expect(rect.midY > caret.minY)
        #expect(rect.midY < caret.maxY)
    }

    @Test func aNewEmptyNumberedItemShowsTheNextNumber() {
        let harness = EditorHarness(markdown: "1. one\n2. two\n")
        harness.select(7)

        harness.type("\n")

        #expect(harness.controller.tailMarker.decoration == .number(3))
    }

    @Test func aNestedNumberedItemStartsAtOne() {
        let harness = EditorHarness(markdown: "1. one\n")
        harness.select(3)
        harness.type("\n")

        _ = harness.controller.indentLists(by: 1)

        #expect(harness.controller.tailMarker.decoration == .number(1))
    }

    @Test func aChecklistInAnEmptyNoteShowsItsCircle() {
        let harness = EditorHarness(markdown: "")

        harness.controller.perform(.list(.checklist))

        #expect(harness.controller.tailMarker.isHidden == false)
        #expect(harness.controller.tailMarker.decoration == .checkbox(done: false))
    }

    @Test func typingOrEndingTheListHidesTheMarker() {
        let harness = EditorHarness(markdown: "- one\n")
        harness.select(3)
        harness.type("\n")

        harness.type("two")

        #expect(harness.controller.tailMarker.isHidden)

        harness.type("\n\n")

        #expect(harness.controller.tailMarker.isHidden)
    }

    @Test func aNewEmptyItemInsideAListHasItsMarker() throws {
        let harness = EditorHarness(markdown: "1. one\n2. two\n")
        harness.select(3)

        harness.type("\n")

        let layout = try #require(harness.textView.textLayoutManager)
        var decorations: [ParagraphDecoration] = []
        layout.enumerateTextLayoutFragments(from: layout.documentRange.location, options: [.ensuresLayout]) { fragment in
            decorations.append((fragment as? RichLayoutFragment)?.decoration ?? .none)
            return true
        }
        #expect(decorations == [.number(1), .number(2), .number(3)])
        #expect(harness.controller.tailMarker.isHidden)
    }

    private func endCaret(in harness: EditorHarness) -> CGRect? {
        guard let layout = harness.textView.textLayoutManager else { return nil }
        var caret: CGRect?
        layout.enumerateTextSegments(in: NSTextRange(location: layout.documentRange.endLocation), type: .standard, options: []) { _, rect, _, _ in
            caret = rect
            return false
        }
        let origin = harness.textView.textContainerOrigin
        return caret?.offsetBy(dx: origin.x, dy: origin.y)
    }
}
