import AppKit
import QuickLookUI
import SwiftUI

struct FilePreview: NSViewRepresentable {
    let url: URL
    let token: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> QLPreviewView {
        let view: QLPreviewView = QLPreviewView(frame: .zero, style: .normal)
        view.shouldCloseWithWindow = false
        view.autostarts = false
        show(in: view, coordinator: context.coordinator)
        return view
    }

    func updateNSView(_ view: QLPreviewView, context: Context) {
        show(in: view, coordinator: context.coordinator)
    }

    static func dismantleNSView(_ view: QLPreviewView, coordinator: Coordinator) {
        view.close()
    }

    private func show(in view: QLPreviewView, coordinator: Coordinator) {
        guard coordinator.url != url || coordinator.token != token else { return }
        let isSameItem = coordinator.url == url
        coordinator.url = url
        coordinator.token = token
        if isSameItem {
            view.refreshPreviewItem()
        } else {
            view.previewItem = url as NSURL
        }
    }

    final class Coordinator {
        var url: URL?
        var token: Int?
    }
}
