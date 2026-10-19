import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerMultiCaretTests {
    private func threeCarets(_ markdown: String = "abc\n\nabc\n\nabc\n", at location: Int = 1) -> EditorHarness {
        let harness = EditorHarness(markdown: markdown)
        harness.select(location)
        #expect(harness.controller.addCaret(.down))
        #expect(harness.controller.addCaret(.down))
        harness.layout()
        return harness
    }

    @Test func controlShiftArrowsAddACaretOnTheNextLine() {
        let harness = threeCarets()

        #expect(harness.controller.caretLocations.sorted() == [1, 5, 9])
        #expect(harness.controller.multiCaret.overlay.rects.count == 2)
    }

    @Test func typingGoesToEveryCaret() {
        let harness = threeCarets()

        harness.type("XY")

        #expect(harness.markdown == "aXYbc\n\naXYbc\n\naXYbc\n")
        #expect(harness.controller.caretLocations.sorted() == [3, 9, 15])
    }

    @Test func oneUndoRemovesTheTypingAtEveryCaret() {
        let harness = threeCarets()
        harness.undoStep { harness.type("X") }

        harness.controller.undoEdit()

        #expect(harness.markdown == "abc\n\nabc\n\nabc\n")
    }

    @Test func backspaceDeletesAtEveryCaretButNotTheLineBreak() {
        let harness = threeCarets(at: 0)
        harness.command(#selector(NSResponder.moveRight(_:)))

        harness.command(#selector(NSResponder.deleteBackward(_:)))
        harness.command(#selector(NSResponder.deleteBackward(_:)))

        #expect(harness.markdown == "bc\n\nbc\n\nbc\n")
        #expect(harness.controller.caretLocations.sorted() == [0, 3, 6])
    }

    @Test func arrowsMoveEveryCaret() {
        let harness = threeCarets()

        harness.command(#selector(NSResponder.moveToRightEndOfLine(_:)))
        harness.type("!")

        #expect(harness.markdown == "abc!\n\nabc!\n\nabc!\n")
    }

    @Test func escapeLeavesOneCaret() {
        let harness = threeCarets()

        harness.command(#selector(NSResponder.cancelOperation(_:)))
        harness.type("X")

        #expect(harness.controller.multiCaret.isActive == false)
        #expect(harness.controller.multiCaret.overlay.isHidden)
        #expect(harness.markdown.components(separatedBy: "X").count == 2)
    }

    @Test func aClickOrAnotherSelectionLeavesOneCaret() {
        let harness = threeCarets()

        harness.select(0)

        #expect(harness.controller.multiCaret.isActive == false)
    }

    @Test func enterLeavesOnlyTheFirstCaretAndWorksAsBefore() {
        let harness = threeCarets()

        harness.type("\n")

        #expect(harness.controller.multiCaret.isActive == false)
        #expect(harness.markdown == "a\n\nbc\n\nabc\n\nabc\n")
    }

    @Test func aFormatCommandLeavesOneCaret() {
        let harness = threeCarets()

        harness.controller.perform(.style(.heading))

        #expect(harness.controller.multiCaret.isActive == false)
    }

    @Test func thereIsNoCaretAboveTheFirstLine() {
        let harness = EditorHarness(markdown: "abc\n\nabc\n")
        harness.select(1)

        #expect(harness.controller.addCaret(.up))

        #expect(harness.controller.multiCaret.isActive == false)
    }

    @Test func linesInACodeBlockGetCaretsToo() {
        let harness = threeCarets("```\nlet a\nlet b\nlet c\n```\n", at: 0)

        harness.type("// ")

        #expect(harness.markdown == "```\n// let a\n// let b\n// let c\n```\n")
    }
}
