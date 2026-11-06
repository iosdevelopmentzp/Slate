import AppKit
import SlateDomain

final class CaptureNoteTextView: NSTextView {
    var onAttach: ([CaptureAttachment]) -> Void = { _ in }

    override func paste(_ sender: Any?) {
        let attachments = PasteboardReader.attachments(in: .general)
        guard attachments.isEmpty == false else {
            super.paste(sender)
            return
        }
        onAttach(attachments)
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        PasteboardReader.attachments(in: sender.draggingPasteboard).isEmpty ? super.draggingEntered(sender) : .copy
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        PasteboardReader.attachments(in: sender.draggingPasteboard).isEmpty ? super.draggingUpdated(sender) : .copy
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let attachments = PasteboardReader.attachments(in: sender.draggingPasteboard)
        guard attachments.isEmpty == false else { return super.performDragOperation(sender) }
        onAttach(attachments)
        return true
    }
}
