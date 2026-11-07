import Foundation
import SlateDomain

package final class SpyWorkspace: WorkspaceOpening, @unchecked Sendable {
    package enum Call: Hashable {
        case open(URL)
        case reveal(URL)
        case quickLook(URL)
        case openCode(String, line: Int?, roots: [URL])
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _codeFound = true

    package init() {}

    package var codeFound: Bool {
        get { lock.withLock { _codeFound } }
        set { lock.withLock { _codeFound = newValue } }
    }

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

    package func openCode(_ path: String, line: Int?, in roots: [URL]) async -> Bool {
        lock.withLock {
            _calls.append(.openCode(path, line: line, roots: roots))
            return _codeFound
        }
    }
}
