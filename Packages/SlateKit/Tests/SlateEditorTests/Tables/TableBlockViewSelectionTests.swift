import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct TableBlockViewSelectionTests {
    private let note = "Intro\n\n| a | b | c |\n|---|---|---|\n| 1 | 2 | 3 |\n| 4 | 5 | 6 |\n"

    private func start() throws -> (EditorHarness, TableBlockView) {
        let harness = EditorHarness(markdown: note)
        let view = try #require(harness.table()?.loadedView)
        return (harness, view)
    }

    private func index(_ row: Int, _ column: Int) -> TableCellIndex {
        TableCellIndex(row: row, column: column)
    }

    private func mouse(_ type: NSEvent.EventType, at cell: TableCellIndex, in view: TableBlockView, _ harness: EditorHarness, flags: NSEvent.ModifierFlags = []) throws -> NSEvent {
        let rect = view.currentLayout.cellRect(cell)
        let point = view.convert(CGPoint(x: rect.midX, y: rect.midY), to: nil)
        return try #require(NSEvent.mouseEvent(with: type, location: point, modifierFlags: flags, timestamp: 0, windowNumber: harness.window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
    }

    @Test func shiftClickSelectsTheCellsBetween() throws {
        let (harness, view) = try start()
        view.beginEditing(index(1, 0))

        view.mouseDown(with: try mouse(.leftMouseDown, at: index(2, 1), in: view, harness, flags: .shift))

        #expect(view.cellSelection == TableCellRange(anchor: index(1, 0), head: index(2, 1)))
        #expect(view.editing == nil)
        #expect(harness.window.firstResponder === view)
    }

    @Test func dragAcrossCellsSelectsThem() throws {
        let (harness, view) = try start()

        view.mouseDown(with: try mouse(.leftMouseDown, at: index(0, 0), in: view, harness))
        view.mouseDragged(with: try mouse(.leftMouseDragged, at: index(1, 2), in: view, harness))

        #expect(view.cellSelection == TableCellRange(anchor: index(0, 0), head: index(1, 2)))
    }

    @Test func shiftArrowAtTheEdgeOfACellStartsASelection() {
        let harness = EditorHarness(markdown: note)
        guard let view = harness.table()?.loadedView else { return }
        view.beginEditing(index(1, 0), caretAtEnd: true)

        view.cellEditor.doCommand(by: #selector(NSResponder.moveRightAndModifySelection(_:)))
        view.doCommand(by: #selector(NSResponder.moveDownAndModifySelection(_:)))

        #expect(view.cellSelection == TableCellRange(anchor: index(1, 0), head: index(2, 1)))
    }

    @Test func deleteClearsTheSelectedCellsInOneStep() throws {
        let (harness, view) = try start()
        view.selectCells(TableCellRange(anchor: index(1, 0), head: index(2, 1)))

        harness.undoStep { view.doCommand(by: #selector(NSResponder.deleteBackward(_:))) }

        #expect(harness.markdown == "Intro\n\n| a | b | c |\n| --- | --- | --- |\n| | | 3 |\n| | | 6 |\n")
        harness.controller.undoEdit()
        #expect(harness.markdown == note.replacingOccurrences(of: "|---|---|---|", with: "|---|---|---|"))
    }

    @Test func boldTogglesEveryCell() throws {
        let (harness, view) = try start()
        view.selectCells(TableCellRange(anchor: index(1, 1), head: index(2, 1)))

        view.slateBold(nil)

        #expect(harness.markdown.contains("| 1 | **2** | 3 |\n| 4 | **5** | 6 |"))
        #expect(view.cellSelection != nil)
    }

    @Test func copyAndPasteMovesABlockOfCells() throws {
        let (harness, view) = try start()
        let board = NSPasteboard(name: NSPasteboard.Name("slate.tests.\(UUID().uuidString)"))
        let attachment = try #require(view.attachment)
        harness.controller.copyCells(attachment, range: TableCellRange(anchor: index(1, 0), head: index(1, 1)), to: board)
        view.selectCells(TableCellRange(anchor: index(2, 1), head: index(2, 1)))

        harness.controller.pasteIntoCells(view, from: board)

        #expect(board.string(forType: .string) == "1\t2")
        #expect(harness.markdown.contains("| 4 | 1 | 2 |"))
        #expect(view.cellSelection == TableCellRange(anchor: index(2, 1), head: index(2, 2)))
    }

    @Test func typingReplacesTheAnchorCell() throws {
        let (harness, view) = try start()
        view.selectCells(TableCellRange(anchor: index(1, 1), head: index(2, 2)))

        view.insertText("x")

        #expect(view.editing == index(1, 1))
        #expect(view.cellEditor.string == "x")
        #expect(harness.window.firstResponder === view.cellEditor)
    }

    @Test func arrowsEndTheSelectionAndEditANeighbour() throws {
        let (_, view) = try start()
        view.selectCells(TableCellRange(anchor: index(1, 0), head: index(1, 1)))

        view.doCommand(by: #selector(NSResponder.moveRight(_:)))

        #expect(view.cellSelection == nil)
        #expect(view.editing == index(1, 2))
    }

    @Test func selectAllTwiceInACellSelectsTheTable() throws {
        let (_, view) = try start()
        view.beginEditing(index(1, 1))

        view.cellEditor.selectAll(nil)
        view.cellEditor.selectAll(nil)

        #expect(view.cellSelection == TableCellRange(anchor: index(0, 0), head: index(2, 2)))
    }

    @Test func theMenuForASelectionActsOnAllOfIt() throws {
        let (harness, view) = try start()
        let selection = TableCellRange(anchor: index(1, 0), head: index(2, 1))
        view.selectCells(selection)

        let menu = TableMenu.menu(for: index(1, 0), model: view.attachment?.model ?? .empty(), target: view, selection: selection)
        let delete = try #require(menu.items.first { $0.title == "Delete Rows" })
        view.tableMenuAction(delete)

        #expect(menu.items.first?.title == "Clear Cells")
        #expect(menu.items.contains { $0.title == "Delete Columns" })
        #expect(harness.markdown == "Intro\n\n| a | b | c |\n| --- | --- | --- |\n| | | |\n")
    }
}
