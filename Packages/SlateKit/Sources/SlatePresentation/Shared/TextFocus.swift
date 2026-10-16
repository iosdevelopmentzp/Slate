import AppKit

@MainActor
enum TextFocus {
    static var isEditingText: Bool {
        NSApp.keyWindow?.firstResponder is NSTextView
    }

    static func send(_ action: Selector) {
        NSApp.sendAction(action, to: nil, from: nil)
    }
}
