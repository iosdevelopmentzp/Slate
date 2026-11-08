import Foundation
import Testing
@testable import SlateEditor

@Suite struct DiagramDrawingTests {

    @Test func aSizeIsRead() {
        #expect(DiagramDrawing.parse(["width": 120, "height": 80]) == .size(CGSize(width: 120, height: 80)))
    }

    @Test func anErrorIsRead() {
        #expect(DiagramDrawing.parse(["error": "Parse error on line 1"]) == .error("Parse error on line 1"))
    }

    @Test func anEmptySizeIsAnError() {
        #expect(DiagramDrawing.parse(["width": 0, "height": 80]) == .error(DiagramDrawing.unknownError))
    }

    @Test func anythingElseIsAnError() {
        #expect(DiagramDrawing.parse(nil) == .error(DiagramDrawing.unknownError))
        #expect(DiagramDrawing.parse(["error": ""]) == .error(DiagramDrawing.unknownError))
    }
}
