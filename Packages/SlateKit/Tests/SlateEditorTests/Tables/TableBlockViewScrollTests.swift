import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct TableBlockViewScrollTests {
    private var wideNote: String {
        let header = (1...8).map { "Column \($0) with a long title" }
        let row = (1...8).map { "Value \($0) that is long enough" }
        return "| " + header.joined(separator: " | ") + " |\n|" + String(repeating: "---|", count: 8) + "\n| " + row.joined(separator: " | ") + " |\n"
    }

    @Test func aWideTableStaysInsideTheTextWidth() throws {
        let harness = EditorHarness(markdown: wideNote)
        let view = try #require(harness.table()?.loadedView)

        #expect(view.frame.width <= harness.textView.textContainer?.size.width ?? 0)
        #expect(view.overflows)
        #expect(view.contentWidth > view.frame.width)
    }

    @Test func scrollingStaysInsideTheContent() throws {
        let harness = EditorHarness(markdown: wideNote)
        let view = try #require(harness.table()?.loadedView)

        view.scroll(to: -40)
        #expect(view.bounds.origin.x == 0)

        view.scroll(to: 10_000)
        #expect(view.bounds.origin.x == view.maxScrollOffset)
        #expect(view.scrollerRect(layout: view.currentLayout) != nil)
    }

    @Test func editingACellOffToTheRightScrollsItIntoView() throws {
        let harness = EditorHarness(markdown: wideNote)
        let view = try #require(harness.table()?.loadedView)
        let last = TableCellIndex(row: 1, column: 7)

        view.beginEditing(last)

        let cell = view.currentLayout.cellRect(last)
        #expect(view.scrollOffset > 0)
        #expect(cell.maxX <= view.bounds.maxX + 0.5)
        #expect(cell.minX >= view.bounds.minX - 0.5)
    }

    @Test func aNarrowTableDoesNotScroll() throws {
        let harness = EditorHarness(markdown: "| a | b |\n|---|---|\n| 1 | 2 |\n")
        let view = try #require(harness.table()?.loadedView)

        view.scroll(to: 50)

        #expect(view.overflows == false)
        #expect(view.bounds.origin.x == 0)
    }
}
