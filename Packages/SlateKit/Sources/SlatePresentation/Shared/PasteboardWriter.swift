import AppKit
import SlateDomain
import SlateUI

@MainActor
enum PasteboardWriter {

    static func write(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
