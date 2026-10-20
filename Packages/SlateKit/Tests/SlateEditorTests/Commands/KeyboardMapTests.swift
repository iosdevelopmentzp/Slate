import AppKit
import Testing
@testable import SlateEditor

@MainActor
@Suite struct KeyboardMapTests {
    private func event(_ key: String, keyCode: UInt16 = 0, flags: NSEvent.ModifierFlags) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0, context: nil, characters: key, charactersIgnoringModifiers: key, isARepeat: false, keyCode: keyCode)!
    }

    @Test func shiftCommandKeysPickTheParagraphStyle() {
        #expect(KeyboardMap.command(for: event("t", flags: [.command, .shift])) == .style(.title))
        #expect(KeyboardMap.command(for: event("h", flags: [.command, .shift])) == .style(.heading))
        #expect(KeyboardMap.command(for: event("j", flags: [.command, .shift])) == .style(.subheading))
        #expect(KeyboardMap.command(for: event("b", flags: [.command, .shift])) == .style(.body))
        #expect(KeyboardMap.command(for: event("m", flags: [.command, .shift])) == .style(.monospaced))
        #expect(KeyboardMap.command(for: event("l", flags: [.command, .shift])) == .list(.checklist))
        #expect(KeyboardMap.command(for: event("&", keyCode: KeyboardMap.digitSeven, flags: [.command, .shift])) == .list(.bullet))
        #expect(KeyboardMap.command(for: event("(", keyCode: KeyboardMap.digitNine, flags: [.command, .shift])) == .list(.numbered))
        #expect(KeyboardMap.command(for: event("x", flags: [.command, .shift])) == .inline(.strikethrough))
        #expect(KeyboardMap.command(for: event("i", flags: [.command, .shift])) == .image)
        #expect(KeyboardMap.command(for: event("a", flags: [.command, .shift])) == .file)
        #expect(KeyboardMap.command(for: event("e", flags: [.command, .shift])) == .highlight(.yellow))
        #expect(KeyboardMap.command(for: event("o", flags: [.command, .shift])) == .outline)
    }

    @Test func optionCommandArrowsCollapseAndExpandSections() {
        #expect(KeyboardMap.command(for: event("", keyCode: KeyboardMap.arrowLeft, flags: [.command, .option])) == .collapseSection)
        #expect(KeyboardMap.command(for: event("", keyCode: KeyboardMap.arrowRight, flags: [.command, .option])) == .expandSection)
        #expect(KeyboardMap.command(for: event("", keyCode: KeyboardMap.arrowLeft, flags: [.command, .option, .shift])) == .collapseAllSections)
        #expect(KeyboardMap.command(for: event("", keyCode: KeyboardMap.arrowRight, flags: [.command, .option, .shift])) == .expandAllSections)
    }

    @Test func optionCommandTInsertsATable() {
        #expect(KeyboardMap.command(for: event("t", flags: [.command, .option])) == .table)
        #expect(KeyboardMap.command(for: event("t", flags: [.command])) == nil)
    }

    @Test func commandKeysFormatText() {
        #expect(KeyboardMap.command(for: event("b", flags: [.command])) == .inline(.bold))
        #expect(KeyboardMap.command(for: event("i", flags: [.command])) == .inline(.italic))
        #expect(KeyboardMap.command(for: event("k", flags: [.command])) == .link)
        #expect(KeyboardMap.command(for: event("'", keyCode: KeyboardMap.quote, flags: [.command])) == .quote)
        #expect(KeyboardMap.command(for: event("]", keyCode: KeyboardMap.rightBracket, flags: [.command])) == .indent(1))
    }

    @Test func otherKeysAreLeftToTheTextView() {
        #expect(KeyboardMap.command(for: event("c", flags: [.command])) == nil)
        #expect(KeyboardMap.command(for: event("b", flags: [.command, .option])) == nil)
        #expect(KeyboardMap.command(for: event("b", flags: [])) == nil)
    }

    @Test func controlShiftArrowsAddACaret() {
        #expect(KeyboardMap.caretDirection(for: event("", keyCode: KeyboardMap.arrowUp, flags: [.control, .shift, .function, .numericPad])) == .up)
        #expect(KeyboardMap.caretDirection(for: event("", keyCode: KeyboardMap.arrowDown, flags: [.control, .shift])) == .down)
        #expect(KeyboardMap.caretDirection(for: event("", keyCode: KeyboardMap.arrowUp, flags: [.shift])) == nil)
        #expect(KeyboardMap.caretDirection(for: event("", keyCode: KeyboardMap.arrowUp, flags: [.control, .shift, .command])) == nil)
    }

    @Test func optionShiftCommandJFormatsJSON() {
        #expect(KeyboardMap.command(for: event("J", flags: [.command, .option, .shift])) == .formatJSON)
    }
}
