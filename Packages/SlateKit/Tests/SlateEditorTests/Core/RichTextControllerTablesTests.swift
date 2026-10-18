import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerTablesTests {
    private let note = "Intro\n\n| a | b |\n|---|---|\n| 1 | 2 |\n\nAfter\n"

    private func editing(_ harness: EditorHarness) -> (TableBlockView, TableCellIndex)? {
        guard let view = harness.table()?.loadedView, let index = view.editing else { return nil }
        return (view, index)
    }

    @Test func downFromTheLineAboveEntersTheHeaderRow() throws {
        let harness = EditorHarness(markdown: note)
        harness.caret(after: "I")

        harness.command(#selector(NSResponder.moveDown(_:)))

        let (view, index) = try #require(editing(harness))
        #expect(index == TableCellIndex(row: 0, column: 0))
        #expect(harness.window.firstResponder === view.cellEditor)
    }

    @Test func downUnderTheSecondColumnEntersTheSecondColumn() throws {
        let harness = EditorHarness(markdown: note.replacingOccurrences(of: "Intro", with: "Introduction and more words"))
        harness.caret(after: "more words")

        harness.command(#selector(NSResponder.moveDown(_:)))

        #expect(try #require(editing(harness)).1 == TableCellIndex(row: 0, column: 1))
    }

    @Test func upFromTheLineBelowEntersTheLastRow() throws {
        let harness = EditorHarness(markdown: note)
        harness.caret(after: "Aft")
        harness.select(harness.textView.selectedRange().location - 3)

        harness.command(#selector(NSResponder.moveUp(_:)))

        #expect(try #require(editing(harness)).1 == TableCellIndex(row: 1, column: 0))
    }

    @Test func rightAtTheEndOfTheLineBeforeEntersTheFirstCell() throws {
        let harness = EditorHarness(markdown: note)
        harness.caret(after: "Intro")

        harness.command(#selector(NSResponder.moveRight(_:)))

        let (view, index) = try #require(editing(harness))
        #expect(index == TableCellIndex(row: 0, column: 0))
        #expect(view.cellEditor.selectedRange() == NSRange(location: 0, length: 0))
    }

    @Test func leftAtTheStartOfTheLineAfterEntersTheLastCellAtItsEnd() throws {
        let harness = EditorHarness(markdown: note)
        harness.caret(after: "Aft")
        harness.select(harness.textView.selectedRange().location - 3)

        harness.command(#selector(NSResponder.moveLeft(_:)))

        let (view, index) = try #require(editing(harness))
        #expect(index == TableCellIndex(row: 1, column: 1))
        #expect(view.cellEditor.selectedRange() == NSRange(location: 1, length: 0))
    }

    private func click(_ cell: TableCellIndex, in view: TableBlockView, _ harness: EditorHarness, flags: NSEvent.ModifierFlags) throws -> NSEvent {
        view.beginEditing(cell)
        let editor = view.cellEditor
        let screen = editor.firstRect(forCharacterRange: NSRange(location: 1, length: 1), actualRange: nil)
        let rect = harness.window.convertFromScreen(screen)
        return try #require(NSEvent.mouseEvent(with: .leftMouseDown, location: CGPoint(x: rect.midX, y: rect.midY), modifierFlags: flags, timestamp: 0, windowNumber: harness.window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
    }

    @Test func commandClickOnALinkInACellOpensIt() throws {
        let harness = EditorHarness(markdown: "| [site](https://example.com) | [[Decisions]] |\n|---|---|\n| 1 | 2 |\n")
        var opened: [EditorLink] = []
        harness.controller.handlers.openLink = { opened.append($0) }
        let view = try #require(harness.table()?.loadedView)

        view.mouseDown(with: try click(TableCellIndex(row: 0, column: 0), in: view, harness, flags: .command))
        view.mouseDown(with: try click(TableCellIndex(row: 0, column: 1), in: view, harness, flags: .command))

        #expect(opened == [.url("https://example.com"), .wiki("Decisions")])
    }

    @Test func aPlainClickOnALinkInACellOnlyPlacesTheCaret() throws {
        let harness = EditorHarness(markdown: "| [site](https://example.com) | b |\n|---|---|\n| 1 | 2 |\n")
        var opened: [EditorLink] = []
        harness.controller.handlers.openLink = { opened.append($0) }
        let view = try #require(harness.table()?.loadedView)

        view.mouseDown(with: try click(TableCellIndex(row: 0, column: 0), in: view, harness, flags: []))

        #expect(opened.isEmpty)
        #expect(view.editing == TableCellIndex(row: 0, column: 0))
    }

    @Test func arrowsAwayFromATableStillMoveTheCaret() {
        let harness = EditorHarness(markdown: "One\nTwo\n")
        harness.caret(after: "On")

        harness.command(#selector(NSResponder.moveRight(_:)))
        #expect(harness.textView.selectedRange() == NSRange(location: 3, length: 0))

        harness.command(#selector(NSResponder.moveDown(_:)))
        #expect(harness.textView.selectedRange().location > 3)
        #expect(harness.table() == nil)
    }
}
