import AppKit

extension RichTextController {

    func copyCode(at location: Int, to pasteboard: NSPasteboard = PasteboardBridge.general) {
        guard let code = codeText(at: location) else { return }
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)
        handlers.notice("Copied the code")
    }
}
