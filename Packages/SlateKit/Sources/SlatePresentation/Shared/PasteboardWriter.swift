import AppKit
import SlateDomain
import SlateUI

@MainActor
enum PasteboardWriter {

    static func write(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    static func writeImage(at url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }
}
