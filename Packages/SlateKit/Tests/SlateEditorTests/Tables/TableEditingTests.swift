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

    @Test func anImportedImageGoesIntoTheCellBeingEdited() {
        let (harness, view) = start()
        type("shelf", in: view)

        harness.controller.imageTarget = view.imageTarget
        harness.controller.apply(insertion: EditorInsertion(token: 41, markdown: "![](../_attachments/a.png)\n![](../_attachments/b.png)"))
        view.leave(after: true)

        #expect(harness.markdown == "Intro\n\n| shelf ![](../_attachments/a.png) ![](../_attachments/b.png) | |\n| --- | --- |\n| | |\n")
    }

    @Test func anImageForACellThatIsNotEditedAnyMoreIsAddedToItsText() {
        let (harness, view) = start()
        type("milk", in: view)
        let target = view.imageTarget
        view.leave(after: true)

        harness.controller.imageTarget = target
        harness.controller.apply(insertion: EditorInsertion(token: 42, markdown: "![](../_attachments/a.png)"))

        #expect(harness.markdown == "Intro\n\n| milk ![](../_attachments/a.png) | |\n| --- | --- |\n| | |\n")
    }

    @Test func pastingAFileIntoACellImportsItForThatCell() throws {
        var pasted: [URL] = []
        let (harness, view) = start()
        harness.controller.handlers.pasteFiles = { pasted = $0 }
        let board = NSPasteboard(name: NSPasteboard.Name("slate.tests.\(UUID().uuidString)"))
        board.clearContents()
        let file = URL(fileURLWithPath: "/tmp/photo.png")
        board.writeObjects([file as NSURL])

        harness.controller.pasteIntoCell(view, from: board)

        #expect(pasted == [file])
        #expect(harness.controller.imageTarget?.cell == TableCellIndex(row: 0, column: 0))
    }

    @Test func theImageButtonInACellKeepsTheTableOpen() {
        var screenshots = 0
        let (harness, view) = start()
        harness.controller.handlers.requestScreenshot = { _ in screenshots += 1 }

        harness.controller.perform(.screenshot)

        #expect(screenshots == 1)
        #expect(view.editing == TableCellIndex(row: 0, column: 0))
        #expect(harness.controller.imageTarget?.cell == TableCellIndex(row: 0, column: 0))
    }

    @Test func doubleClickOnACellImageAsksForQuickLook() {
        var looked: [String] = []
        let (harness, _) = start()
        harness.controller.handlers.attachment = { path, action in if action == .quickLook { looked.append(path) } }

        harness.controller.quickLook("../_attachments/a.png")

        #expect(looked == ["../_attachments/a.png"])
    }

    @Test func cellImagesShowAsThumbnails() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("slate-cell-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let image = NSImage(size: CGSize(width: 40, height: 20), flipped: false) { rect in
            NSColor.systemBlue.setFill()
            rect.fill()
            return true
        }
        let url = folder.appendingPathComponent("a.png")
        let rep = try #require(image.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:)))
        try #require(rep.representation(using: .png, properties: [:])).write(to: url)
        let harness = EditorHarness(markdown: "| a | b |\n|---|---|\n| ![](../_attachments/a.png) | 2 |\n", resolveImage: { _ in url })

        let text = try #require(harness.table()?.text(TableCellIndex(row: 1, column: 0)))
        let thumbnail = try #require(text.attribute(.attachment, at: 0, effectiveRange: nil) as? CellImageAttachment)

        #expect(thumbnail.bounds.size == CGSize(width: 160, height: 80))
        #expect(thumbnail.path == "../_attachments/a.png")
    }

    @Test func aClickOnAnotherCellMovesTheEditorThere() throws {
        let (harness, view) = start()
        type("Item", in: view)
        let rect = view.currentLayout.textRect(TableCellIndex(row: 1, column: 1))
        let point = view.convert(CGPoint(x: rect.minX + 1, y: rect.midY), to: nil)
        let event = try #require(NSEvent.mouseEvent(with: .leftMouseDown, location: point, modifierFlags: [], timestamp: 0, windowNumber: harness.window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))

        view.mouseDown(with: event)

        #expect(view.editing == TableCellIndex(row: 1, column: 1))
        #expect(harness.window.firstResponder === view.cellEditor)
        #expect(view.cellEditor.selectedRange() == NSRange(location: 0, length: 0))
        #expect(harness.markdown == "Intro\n\n| Item | |\n| --- | --- |\n| | |\n")
    }
}
