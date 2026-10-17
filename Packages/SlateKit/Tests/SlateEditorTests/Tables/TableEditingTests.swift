import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct TableEditingTests {
    private func start(_ markdown: String = "Intro\n") -> (EditorHarness, TableBlockView) {
        let harness = EditorHarness(markdown: markdown)
        harness.caret(after: "Intro")
        harness.undoStep { harness.controller.perform(.table) }
        harness.controller.undoManager.groupsByEvent = true
        harness.layout()
        let view = harness.table()?.view() ?? TableBlockView(attachment: TableAttachment(block: TableBlock(model: .empty()), style: TableStyle()))
        return (harness, view)
    }

    private func type(_ text: String, in view: TableBlockView) {
        view.cellEditor.insertText(text, replacementRange: view.cellEditor.selectedRange())
    }

    private func command(_ selector: Selector, in view: TableBlockView) {
        view.cellEditor.doCommand(by: selector)
    }

    @Test func insertingATableStartsInTheFirstCell() {
        let (harness, view) = start()

        #expect(view.editing == TableCellIndex(row: 0, column: 0))
        #expect(harness.window.firstResponder === view.cellEditor)
        #expect(harness.markdown == "Intro\n\n| | |\n| --- | --- |\n| | |\n")
    }

    @Test func tabFillsCellsAndTabOnTheLastCellAddsARow() {
        let (harness, view) = start()

        for text in ["Item", "Count", "Milk", "2"] {
            type(text, in: view)
            command(#selector(NSResponder.insertTab(_:)), in: view)
        }

        #expect(view.editing == TableCellIndex(row: 2, column: 0))
        #expect(harness.markdown == "Intro\n\n| Item | Count |\n| --- | --- |\n| Milk | 2 |\n| | |\n")
    }

    @Test func returnMovesDownAndAddsARowAtTheEnd() {
        let (harness, view) = start()

        type("a", in: view)
        command(#selector(NSResponder.insertNewline(_:)), in: view)
        type("b", in: view)
        command(#selector(NSResponder.insertNewline(_:)), in: view)

        #expect(view.editing == TableCellIndex(row: 2, column: 0))
        #expect(harness.markdown == "Intro\n\n| a | |\n| --- | --- |\n| b | |\n| | |\n")
    }

    @Test func boldInsideACellIsWrittenAsMarkdown() {
        let (harness, view) = start()
        type("big deal", in: view)
        view.cellEditor.setSelectedRange(NSRange(location: 0, length: 3))

        view.cellEditor.toggle(.bold)
        view.leave(after: true)

        #expect(harness.markdown == "Intro\n\n| **big** deal | |\n| --- | --- |\n| | |\n")
        #expect(harness.window.firstResponder === harness.textView)
    }

    @Test func escLeavesTheTableBelowAndUpLeavesItAbove() {
        let (harness, view) = start("Intro\n\nAfter\n")

        command(#selector(NSResponder.cancelOperation(_:)), in: view)
        #expect(harness.window.firstResponder === harness.textView)
        #expect(harness.textView.selectedRange().location == (harness.text as NSString).range(of: "After").location)

        view.beginEditing(TableCellIndex(row: 0, column: 1))
        command(#selector(NSResponder.moveUp(_:)), in: view)
        #expect(harness.textView.selectedRange().location == 5)
    }

    @Test func eachCellEditIsOneUndoStep() {
        let (harness, view) = start()
        harness.undoStep {
            type("one", in: view)
            command(#selector(NSResponder.insertTab(_:)), in: view)
        }
        harness.undoStep {
            type("two", in: view)
            view.leave(after: true)
        }
        #expect(harness.markdown == "Intro\n\n| one | two |\n| --- | --- |\n| | |\n")

        harness.controller.undoEdit()

        #expect(harness.markdown == "Intro\n\n| one | |\n| --- | --- |\n| | |\n")
    }

    @Test func structureChangesFromTheHandleAndTheMenu() {
        let (harness, view) = start()
        type("a", in: view)

        view.addColumn(at: 2, focus: TableCellIndex(row: 0, column: 2))
        type("c", in: view)
        view.change({ $0.setAlignment(.center, column: 2) }, focus: nil)
        view.change({ $0.insertRow(at: 1) }, focus: nil)
        view.leave(after: true)

        #expect(harness.markdown == "Intro\n\n| a | | c |\n| --- | --- | :---: |\n| | | |\n| | | |\n")
    }

    @Test func deletingATableWithOneFilledCellNeedsNoConfirmation() {
        let (harness, view) = start()
        type("only", in: view)
        view.commit()

        view.requestDeleteTable()

        #expect(harness.markdown == "Intro\n")
    }

    @Test func flushWritesTheCellBeingTyped() {
        let (harness, view) = start()
        type("typing", in: view)

        harness.controller.flush()

        #expect(harness.controller.markdown == "Intro\n\n| typing | |\n| --- | --- |\n| | |\n")
        #expect(view.editing == TableCellIndex(row: 0, column: 0))
    }

    @Test func aNewLineInACellBecomesASpace() {
        let (harness, view) = start()

        type("a\nb", in: view)
        view.leave(after: true)

        #expect(harness.markdown == "Intro\n\n| a b | |\n| --- | --- |\n| | |\n")
    }
}
