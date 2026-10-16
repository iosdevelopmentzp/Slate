import AppKit
import SlateDomain

struct WorkspaceOpener: WorkspaceOpening {
    let quickLook = QuickLookPresenter()

    func open(_ url: URL) async {
        await MainActor.run {
            _ = NSWorkspace.shared.open(url)
        }
    }

    func reveal(_ url: URL) async {
        await MainActor.run {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    func quickLook(_ url: URL) async {
        await quickLook.present(url)
    }
}
