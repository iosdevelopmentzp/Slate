import AppKit

enum PasteboardBridge {
    static var general: NSPasteboard {
        .general
    }

    static func plainText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }
}
