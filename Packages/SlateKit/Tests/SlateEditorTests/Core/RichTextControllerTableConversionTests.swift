import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerTableConversionTests {
    @Test func selectedLinesWithTabsBecomeATable() {
        let harness = EditorHarness(markdown: "Intro\n\nName\tCount\n\n**Milk**\t2\n\nBread\t1\n\nAfter\n")
        harness.select(6, 22)

        harness.controller.perform(.table)

        #expect(harness.markdown == "Intro\n\n| Name | Count |\n| --- | --- |\n| **Milk** | 2 |\n| Bread | 1 |\n\nAfter\n")
        #expect(harness.table() != nil)
    }

    @Test func linesWithPipesBecomeATableAndTheDelimiterRowIsDropped() {
        let harness = EditorHarness(markdown: "a | b\n\n--- | ---\n\n1 | 2\n")
        harness.select(0, (harness.text as NSString).length)

        harness.controller.perform(.table)

        #expect(harness.markdown == "| a | b |\n| --- | --- |\n| 1 | 2 |\n")
    }

    @Test func plainLinesBecomeOneColumn() {
        let harness = EditorHarness(markdown: "- milk\n- bread\n- eggs\n")
        harness.select(0, (harness.text as NSString).length)

        harness.controller.perform(.table)

        #expect(harness.markdown == "| milk |\n| --- |\n| bread |\n| eggs |\n")
    }

    @Test func oneLineGetsAnEmptyRow() {
        let harness = EditorHarness(markdown: "Name\tCount\n")
        harness.select(0, 10)

        harness.controller.perform(.table)

        #expect(harness.markdown == "| Name | Count |\n| --- | --- |\n| | |\n")
    }

    @Test func theConversionIsOneUndoStep() {
        let harness = EditorHarness(markdown: "a\tb\n\n1\t2\n")
        harness.select(0, 7)
        harness.undoStep { harness.controller.perform(.table) }

        harness.controller.undoEdit()

        #expect(harness.markdown == "a\tb\n\n1\t2\n")
    }

    @Test func aTableTurnsBackIntoLinesWithTabs() throws {
        let harness = EditorHarness(markdown: "Intro\n\n| Name | Count |\n|---|---|\n| **Milk** | 2 |\n\nAfter\n")

        harness.controller.convertTableToText(try #require(harness.table()))

        #expect(harness.markdown == "Intro\n\nName\tCount\n\n**Milk**\t2\n\nAfter\n")
        #expect(harness.table() == nil)
    }

    @Test func imagesInCellsMoveUnderTheirLine() throws {
        let harness = EditorHarness(markdown: "| Item | Photo |\n|---|---|\n| Milk | ![](../_attachments/a.png) |\n")

        harness.controller.convertTableToText(try #require(harness.table()))

        #expect(harness.markdown == "Item\tPhoto\n\nMilk\n\n![](../_attachments/a.png)\n")
    }

    @Test func theTableMenuOffersConvertToText() {
        let menu = TableMenu.menu(for: TableCellIndex(row: 0, column: 0), model: .empty(), target: NSObject())

        #expect(menu.items.map(\.title).contains("Convert to Text"))
    }
}
