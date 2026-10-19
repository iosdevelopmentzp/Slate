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

    @Test func gripsShowForTheRowAndColumnUnderThePointer() {
        let layout = TableLayout(columnWidths: [60, 80], rowHeights: [30, 30, 30])

        #expect(layout.grips(near: CGPoint(x: 30, y: 45)) == [.row(1), .column(0)])
        #expect(layout.grips(near: CGPoint(x: 100, y: 15)) == [.column(1)])
        #expect(layout.grip(at: CGPoint(x: 3, y: 45)) == .row(1))
    }

    @Test func aPlusShowsAtABorderNearTheEdge() {
        let layout = TableLayout(columnWidths: [60, 80], rowHeights: [30, 30, 30])

        #expect(layout.grip(at: CGPoint(x: 5, y: 61)) == .insertRow(2))
        #expect(layout.grip(at: CGPoint(x: 61, y: 4)) == .insertColumn(1))
        #expect(layout.grips(near: CGPoint(x: 40, y: 61)).contains(.insertRow(2)) == false)
        #expect(layout.grips(near: CGPoint(x: 5, y: 1)).contains(.insertRow(0)) == false)
    }

    @Test func aDropGoesToTheNearestBorder() {
        let layout = TableLayout(columnWidths: [60, 80], rowHeights: [30, 30, 30])

        #expect(layout.rowInsertion(atY: 5) == 1)
        #expect(layout.rowInsertion(atY: 70) == 2)
        #expect(layout.rowInsertion(atY: 200) == 3)
        #expect(layout.columnInsertion(atX: 130) == 2)
    }
}
