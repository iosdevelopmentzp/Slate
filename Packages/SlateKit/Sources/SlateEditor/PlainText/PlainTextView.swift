import AppKit
import QuickLookUI

final class PlainTextView: NSTextView {
    nonisolated override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        false
    }
}
