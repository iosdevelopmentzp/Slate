import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel", default: .init(.n, modifiers: [.option, .command]))
    static let capture = Self("capture", default: .init(.space, modifiers: [.control, .option]))
    static let newNote = Self("newNote")
}
