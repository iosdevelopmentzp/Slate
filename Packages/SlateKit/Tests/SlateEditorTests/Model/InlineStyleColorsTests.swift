import Foundation
import Testing
@testable import SlateEditor

@MainActor
@Suite struct InlineStyleColorsTests {
    @Test func colourBitsDoNotChangeTheOtherStyles() {
        var style = InlineStyle([.bold, .code])
        style.highlight = .purple
        style.textColor = .gray

        #expect(style.contains(.bold))
        #expect(style.contains(.code))
        #expect(style.contains(.italic) == false)
        #expect(style.formattingOnly == [.bold, .code])
        style.highlight = nil
        #expect(style.highlight == nil)
        #expect(style.textColor == .gray)
    }
}
