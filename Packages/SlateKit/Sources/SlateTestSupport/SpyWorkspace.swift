import Foundation
import SlateDomain

package final class SpyWorkspace: WorkspaceOpening, @unchecked Sendable {
    package enum Call: Hashable {
        case open(URL)
        case reveal(URL)
        case quickLook(URL)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package func open(_ url: URL) async {
        lock.withLock { _calls.append(.open(url)) }
    }

    package func reveal(_ url: URL) async {
        lock.withLock { _calls.append(.reveal(url)) }
    }

    package func quickLook(_ url: URL) async {
        lock.withLock { _calls.append(.quickLook(url)) }
    }
}
