import AppKit

enum KeyboardMap {
    static let digitSeven: UInt16 = 26
    static let digitNine: UInt16 = 25
    static let quote: UInt16 = 39
    static let leftBracket: UInt16 = 33
    static let rightBracket: UInt16 = 30
    static let arrowUp: UInt16 = 126
    static let arrowDown: UInt16 = 125
    static let arrowLeft: UInt16 = 123
    static let arrowRight: UInt16 = 124

    static func tableMove(for event: NSEvent) -> TableMenu.Action? {
        guard event.modifierFlags.intersection([.command, .shift, .option, .control]) == [.command, .option] else { return nil }
        switch event.keyCode {
        case arrowUp: return .moveRowUp
        case arrowDown: return .moveRowDown
        case arrowLeft: return .moveColumnLeft
        case arrowRight: return .moveColumnRight
        default: return nil
        }
    }

    static func tableKey(for action: TableMenu.Action) -> String? {
        let key: Int
        switch action {
        case .moveRowUp: key = NSUpArrowFunctionKey
        case .moveRowDown: key = NSDownArrowFunctionKey
        case .moveColumnLeft: key = NSLeftArrowFunctionKey
        case .moveColumnRight: key = NSRightArrowFunctionKey
        default: return nil
        }
        return UnicodeScalar(key).map { String(Character($0)) }
    }

    static func caretDirection(for event: NSEvent) -> CaretDirection? {
        guard event.modifierFlags.intersection([.command, .shift, .option, .control]) == [.control, .shift] else { return nil }
        switch event.keyCode {
        case arrowUp: return .up
        case arrowDown: return .down
        default: return nil
        }
    }

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
            case "a": return .file
            case "s": return .screenshot
            default: return nil
            }
        }
        if flags == [.command, .option, .shift], key == "j" {
            return .formatJSON
        }
        if flags == [.command, .option], key == "t" {
            return .table
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
