import AppKit
import Quartz

@MainActor
final class QuickLookSource: NSObject, QLPreviewPanelDataSource {
    private var item: NSURL?

    func present(_ url: URL) {
        item = url as NSURL
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.reloadData()
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        item == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        item
    }
}
