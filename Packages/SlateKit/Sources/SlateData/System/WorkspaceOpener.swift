import AppKit
import SlateDomain

struct WorkspaceOpener: WorkspaceOpening {
    let quickLookSource: QuickLookSource

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
        await quickLookSource.present(url)
    }
}
