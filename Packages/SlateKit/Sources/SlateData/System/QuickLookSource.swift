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
        raise(panel)
    }

    private func raise(_ panel: QLPreviewPanel) {
        let others = NSApp.windows.filter { $0 !== panel && $0.isVisible }.map(\.level.rawValue)
        guard let level = Self.level(for: panel.level.rawValue, above: others) else { return }
        panel.level = NSWindow.Level(rawValue: level)
    }

    static func level(for current: Int, above others: [Int]) -> Int? {
        guard let top = others.max(), top >= current else { return nil }
        return top + 1
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        item == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        item
    }
}
