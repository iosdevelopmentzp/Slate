import AppKit
import Testing
@testable import SlateEditor

@Suite struct DiagramLayoutTests {

    @Test func aSmallDiagramKeepsItsSize() {
        let size = DiagramLayout.displaySize(of: CGSize(width: 200, height: 100), blockWidth: 600, scale: 1)

        #expect(size == CGSize(width: 200, height: 100))
    }

    @Test func aWideDiagramShrinksToTheBlock() {
        let size = DiagramLayout.displaySize(of: CGSize(width: 1000, height: 500), blockWidth: 524, scale: 1)

        #expect(size == CGSize(width: 500, height: 250))
    }

    @Test func theTextSizeScalesTheDiagram() {
        let size = DiagramLayout.displaySize(of: CGSize(width: 200, height: 100), blockWidth: 600, scale: 1.5)

        #expect(size == CGSize(width: 300, height: 150))
    }

    @Test func aDiagramNotDrawnYetGetsAPlaceholder() {
        #expect(DiagramLayout.areaHeight(of: nil, blockWidth: 600, scale: 1) == DiagramLayout.pendingHeight)
    }

    @Test func theAreaHoldsThePictureAndTheError() {
        let picture = DiagramPicture(image: NSImage(size: CGSize(width: 200, height: 100)), size: CGSize(width: 200, height: 100), error: "Parse error on line 2:\nA -->")

        let height = DiagramLayout.areaHeight(of: picture, blockWidth: 600, scale: 1)

        #expect(height == 100 + DiagramLayout.topPadding + DiagramLayout.padding + DiagramLayout.errorGap + DiagramLayout.errorLineHeight * 2)
    }

    @Test func anErrorShowsAtMostFourLines() {
        let lines = DiagramLayout.errorLines("one\n\ntwo\nthree\nfour\nfive")

        #expect(lines == ["one", "two", "three", "four"])
    }
}
