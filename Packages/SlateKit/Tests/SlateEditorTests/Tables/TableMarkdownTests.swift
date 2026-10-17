import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct TableMarkdownTests {
    @Test func aPipeTableBecomesOneTableBlock() throws {
        let text = MarkdownReader.read("| a | b |\n| --- | :---: |\n| 1 | 2 |\n")
        let block = BlockAttributes(text.attributes(at: 0, effectiveRange: nil))

        #expect(text.string == RichText.attachmentString)
        #expect(block.kind == .table)
        let model = try #require(block.table?.model)
        #expect(model.header.map(\.markdown) == ["a", "b"])
        #expect(model.rows.map { $0.map(\.markdown) } == [["1", "2"]])
        #expect(model.columns.map(\.alignment) == [.none, .center])
    }

    @Test func alignmentMarkersAreRead() throws {
        let model = try #require(TableMarkdown.parse("| a | b | c | d |\n|---|:--|:-:|--:|"))

        #expect(model.columns.map(\.alignment) == [.none, .left, .center, .right])
        #expect(model.rows.isEmpty)
    }

    @Test func escapedPipesStayInTheCell() throws {
        let model = try #require(TableMarkdown.parse("| a \\| b | `x\\|y` |\n|---|---|\n| \\\\| c |"))

        #expect(model.header.map(\.markdown) == ["a | b", "`x|y`"])
        #expect(model.rows[0].map(\.markdown) == ["\\\\", "c"])
    }

    @Test func renderingEscapesPipesAndWritesTheMarkers() {
        var model = TableModel.empty(columns: 3, rows: 1)
        model.setCell(TableCellIndex(row: 0, column: 0), markdown: "Name")
        model.setCell(TableCellIndex(row: 0, column: 1), markdown: "a | b")
        model.setCell(TableCellIndex(row: 1, column: 0), markdown: "**x**")
        model.setAlignment(.right, column: 2)

        #expect(TableMarkdown.render(model) == "| Name | a \\| b | |\n| --- | --- | ---: |\n| **x** | | |")
        #expect(TableMarkdown.parse(TableMarkdown.render(model)) == model)
    }

    @Test func aBrokenTableStaysARawBlock() {
        let source = "| a | b |\n|---|---|\n| 1 |\n"
        let text = MarkdownReader.read(source)

        #expect(BlockAttributes(text.attributes(at: 0, effectiveRange: nil)).kind == .raw)
        #expect(MarkdownWriter.write(text) == source)
    }

    @Test func anImageInACellIsReadAndWrittenBack() throws {
        let harness = EditorHarness(markdown: "| a | b |\n|---|---|\n| ![](../_attachments/x.png) | 2 |\n")
        let table = try #require(harness.table())

        var model = table.model
        model.setCell(TableCellIndex(row: 1, column: 1), markdown: "3")
        harness.controller.tableDidChange(table, model: model, before: table.model)

        #expect(harness.markdown == "| a | b |\n| --- | --- |\n| ![](../_attachments/x.png) | 3 |\n")
    }

    @Test func aCellWithABlockStaysRaw() {
        let source = "| a | b |\n|---|---|\n| # not inline | 2 |\n"

        #expect(BlockAttributes(MarkdownReader.read(source).attributes(at: 0, effectiveRange: nil)).kind == .raw)
    }

    @Test func cellsKeepTheirInlineStyles() throws {
        let text = MarkdownReader.read("| **bold** | [link](https://example.com) |\n|---|---|\n")
        let model = try #require(BlockAttributes(text.attributes(at: 0, effectiveRange: nil)).table?.model)

        let bold = try #require(TableCellText.inline(model.header[0].markdown))
        let link = try #require(TableCellText.inline(model.header[1].markdown))

        #expect(bold.string == "bold")
        #expect(bold.attribute(.slateInline, at: 0, effectiveRange: nil) as? Int == InlineStyle.bold.rawValue)
        #expect(link.attribute(.slateHref, at: 0, effectiveRange: nil) as? String == "https://example.com")
        #expect(TableCellText.markdown(of: bold) == "**bold**")
    }

    @Test func anUnchangedTableIsWrittenByteForByte() throws {
        let source = try EditorHarness.fixture("Foreign/obsidian-table")
        let harness = EditorHarness(markdown: source)
        harness.caret(after: "Plan for the week")

        harness.type(" and more")

        #expect(harness.markdown == source.replacingOccurrences(of: "Plan for the week", with: "Plan for the week and more"))
    }

    @Test func anEditedTableIsWrittenInTheCanonicalForm() throws {
        let harness = EditorHarness(markdown: "|a|b|\n|:-|-:|\n|1|2|\n")
        let table = try #require(harness.table())

        harness.controller.tableDidChange(table, model: { var model = table.model; model.setCell(TableCellIndex(row: 1, column: 1), markdown: "3"); return model }(), before: table.model)

        #expect(harness.markdown == "| a | b |\n| :--- | ---: |\n| 1 | 3 |\n")
    }
}
