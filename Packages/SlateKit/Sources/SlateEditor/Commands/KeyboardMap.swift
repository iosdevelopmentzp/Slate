import AppKit

enum KeyboardMap {
    static let digitSeven: UInt16 = 26
    static let digitNine: UInt16 = 25
    static let quote: UInt16 = 39
    static let leftBracket: UInt16 = 33
    static let rightBracket: UInt16 = 30

    static func command(for event: NSEvent) -> EditorCommand? {
        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        if flags == [.command, .shift] {
            switch event.keyCode {
            case digitSeven: return .list(.bullet)
            case digitNine: return .list(.numbered)
            default: break
            }
            switch key {
            case "t": return .style(.title)
            case "h": return .style(.heading)
            case "j": return .style(.subheading)
            case "b": return .style(.body)
            case "m": return .style(.monospaced)
            case "l": return .list(.checklist)
            case "x": return .inline(.strikethrough)
            case "i": return .image
            case "s": return .screenshot
            default: return nil
            }
        }
        if flags == [.command] {
            switch event.keyCode {
            case quote: return .quote
            case rightBracket: return .indent(1)
            case leftBracket: return .indent(-1)
            default: break
            }
            switch key {
            case "b": return .inline(.bold)
            case "i": return .inline(.italic)
            case "k": return .link
            default: return nil
            }
        }
        return nil
    }
}
