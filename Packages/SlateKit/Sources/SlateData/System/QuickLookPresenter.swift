import AppKit
import SlateDomain

final class QuickLookPresenter: Sendable {
    @MainActor private var source: QuickLookSource?

    @MainActor
    func present(_ url: URL) {
        let source = source ?? QuickLookSource()
        self.source = source
        source.present(url)
    }
}
