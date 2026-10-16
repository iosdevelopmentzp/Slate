import Foundation
import Testing
@testable import SlateEditor

@Suite struct WrapSelectionTests {
    private func apply(_ text: String, _ selection: NSRange, _ marker: String) -> (String, NSRange) {
        let edit = WrapSelection.wrap(text as NSString, selection: selection, marker: marker)
        return ((text as NSString).replacingCharacters(in: edit.range, with: edit.replacement), edit.selection)
    }

    @Test func wrapsTheSelection() {
        let (text, selection) = apply("make bold", NSRange(location: 5, length: 4), "**")

        #expect(text == "make **bold**")
        #expect(selection == NSRange(location: 7, length: 4))
    }

    @Test func unwrapsWhenTheMarksSurroundTheSelection() {
        let (text, selection) = apply("make **bold**", NSRange(location: 7, length: 4), "**")

        #expect(text == "make bold")
        #expect(selection == NSRange(location: 5, length: 4))
    }

    @Test func unwrapsWhenTheSelectionHoldsTheMarks() {
        let (text, _) = apply("`code`", NSRange(location: 0, length: 6), "`")

        #expect(text == "code")
    }

    @Test func emptySelectionPlacesTheCaretBetweenTheMarks() {
        let (text, selection) = apply("a ", NSRange(location: 2, length: 0), "*")

        #expect(text == "a **")
        #expect(selection == NSRange(location: 3, length: 0))
    }
}
