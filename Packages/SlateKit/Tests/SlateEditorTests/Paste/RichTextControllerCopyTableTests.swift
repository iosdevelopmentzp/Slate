import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct RichTextControllerCopyTableTests {
    private let note = "| Item | Note |\n|---|:-:|\n| **milk** | two<br>bottles |\n| bread | ![](../_attachments/a.png) fresh |\n"

    private func board() -> NSPasteboard {
        NSPasteboard(name: NSPasteboard.Name("slate.tests.\(UUID().uuidString)"))
    }

    @Test func copyAsMarkdownKeepsTheSource() throws {
        let harness = EditorHarness(markdown: note)
        let pasteboard = board()

        harness.controller.copyTable(try #require(harness.table()), asText: false, to: pasteboard)

        let expected = "| Item | Note |\n|---|:-:|\n| **milk** | two<br>bottles |\n| bread | ![](../_attachments/a.png) fresh |"
        #expect(pasteboard.string(forType: .string) == expected)
        #expect(pasteboard.string(forType: PasteboardReader.markdownType) == expected)
    }

    @Test func copyAsTextGivesTabsAndLines() throws {
        let harness = EditorHarness(markdown: note)
        let pasteboard = board()

        harness.controller.copyTable(try #require(harness.table()), asText: true, to: pasteboard)

        #expect(pasteboard.string(forType: .string) == "Item\tNote\nmilk\ttwo bottles\nbread\tfresh")
        #expect(pasteboard.string(forType: PasteboardReader.markdownType)?.hasPrefix("| Item | Note |") == true)
    }

    @Test func aCopiedTablePastesBackAsATable() throws {
        let harness = EditorHarness(markdown: note + "\nAfter\n")
        let pasteboard = board()
        harness.controller.copyTable(try #require(harness.table()), asText: true, to: pasteboard)
        harness.caret(after: "After")

        harness.controller.paste(from: pasteboard)

        #expect(harness.table(at: 1)?.model == harness.table(at: 0)?.model)
    }

    @Test func theTableMenuOffersBothCopies() {
        let menu = TableMenu.menu(for: TableCellIndex(row: 1, column: 0), model: .empty(), target: NSObject())

        #expect(menu.items.map(\.title).contains("Copy Table as Markdown"))
        #expect(menu.items.map(\.title).contains("Copy Table as Text"))
    }
}
