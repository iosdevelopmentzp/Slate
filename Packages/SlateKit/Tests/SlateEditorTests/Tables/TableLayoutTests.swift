import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct TableLayoutTests {
    private func texts(columns: Int, word: String) -> [[NSAttributedString]] {
        let font = NSFont.systemFont(ofSize: 15)
        let cell = NSAttributedString(string: word, attributes: [.font: font])
        return Array(repeating: Array(repeating: cell, count: columns), count: 2)
    }

    @Test func aNarrowTableKeepsItsWidths() {
        let layout = TableLayout.make(texts: texts(columns: 2, word: "milk"), available: 600, lineHeight: 18)

        #expect(layout.size.width < 600)
        #expect(layout.columnWidths.allSatisfy { $0 == TableLayout.minimumColumn })
    }

    @Test func aWideTableShrinksToFitWhileColumnsStayReadable() {
        let long = String(repeating: "word ", count: 12)
        let layout = TableLayout.make(texts: texts(columns: 3, word: long), available: 600, lineHeight: 18)

        #expect(layout.size.width <= 600)
        #expect(layout.columnWidths.allSatisfy { $0 >= TableLayout.readableColumn })
    }

    @Test func aVeryWideTableStopsAtReadableColumnsAndGetsWider() {
        let long = String(repeating: "word ", count: 12)
        let layout = TableLayout.make(texts: texts(columns: 8, word: long), available: 600, lineHeight: 18)

        #expect(layout.columnWidths.allSatisfy { $0 == TableLayout.readableColumn })
        #expect(layout.size.width == TableLayout.readableColumn * 8)
    }

    @Test func columnAtXFindsTheColumnAndClampsAtTheEnds() {
        let layout = TableLayout(columnWidths: [100, 50, 80], rowHeights: [30])

        #expect(layout.column(atX: -5) == 0)
        #expect(layout.column(atX: 120) == 1)
        #expect(layout.column(atX: 500) == 2)
    }
}
