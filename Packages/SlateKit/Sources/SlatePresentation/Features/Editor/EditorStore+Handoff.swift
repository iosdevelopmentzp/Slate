import Foundation
import SlateDomain

extension EditorStore {
    func copyPath() {
        guard let document else { return }
        toaster.copy(vaultRoot.appendingPathComponent(document.path.rawValue, isDirectory: false).path, label: "Path")
    }

    func copyLink() {
        guard let document, let link = NoteLinkPolicy.openLink(for: document.id) else { return }
        toaster.copy(link.absoluteString, label: "Link")
    }
}
