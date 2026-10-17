import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct TablePasteTests {
    private func pasteboard(_ text: String) -> NSPasteboard {
        let board = NSPasteboard(name: NSPasteboard.Name("slate.tests.\(UUID().uuidString)"))
        board.clearContents()
        board.setString(text, forType: .string)
        return board
    }

    @Test func gfmTextIsRecognised() {
        #expect(TableMarkdown.looksLikeTable("| a | b |\n|---|---|\n| 1 | 2 |\n"))
        #expect(TableMarkdown.looksLikeTable("a | b\n--- | ---"))
        #expect(TableMarkdown.looksLikeTable("Title\n---") == false)
        #expect(TableMarkdown.looksLikeTable("| a | b |") == false)
    }

    @Test func pastingGFMTextInsertsATable() throws {
        let harness = EditorHarness(markdown: "Before\n")
        harness.select(6)

        harness.controller.paste(from: pasteboard("| a | b |\n|---|---|\n| 1 | 2 |"))

        #expect(harness.markdown == "Before\n\n| a | b |\n|---|---|\n| 1 | 2 |\n")
        #expect(harness.table() != nil)
    }

    @Test func tabSeparatedRowsBecomeAModel() throws {
        let model = try #require(TableSeparatedText.model(from: "Name\tCount\nMilk*\t2\nBread\n"))

        #expect(model.header.map(\.markdown) == ["Name", "Count"])
        #expect(model.rows.map { $0.map(\.markdown) } == [["Milk\\*", "2"], ["Bread", ""]])
        #expect(TableSeparatedText.model(from: "one column\nonly") == nil)
    }

    @Test func pasteAsTableTurnsSpreadsheetRowsIntoATable() {
        let harness = EditorHarness(markdown: "Before\n")
        harness.select(6)

        harness.controller.pasteAsTable(from: pasteboard("Name\tCount\nMilk\t2"))

        #expect(harness.markdown == "Before\n\n| Name | Count |\n| --- | --- |\n| Milk | 2 |\n")
    }

    @Test func plainTextStaysText() {
        let harness = EditorHarness(markdown: "Before\n")
        harness.select(6)

        harness.controller.pasteAsTable(from: pasteboard(" after"))

        #expect(harness.markdown == "Before after\n")
    }

    @Test func copyingATableGivesGFM() throws {
        let harness = EditorHarness(markdown: "| a | b |\n| --- | --- |\n| 1 | 2 |\n")
        harness.select(0, 1)
        let board = pasteboard("")

        #expect(harness.controller.copySelection(to: board))

        #expect(board.string(forType: .string) == "| a | b |\n| --- | --- |\n| 1 | 2 |")
        #expect(board.string(forType: PasteboardReader.markdownType) == "| a | b |\n| --- | --- |\n| 1 | 2 |")
    }
}
