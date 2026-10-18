import Foundation
import SlateDomain

package final class SpyRepositoryInspector: RepositoryInspecting, @unchecked Sendable {
    private let lock = NSLock()
    private var _inspected: [URL] = []
    private var _result: RepositoryInfo?

    package init() {}

    package var inspected: [URL] {
        lock.withLock { _inspected }
    }

    package var result: RepositoryInfo? {
        get { lock.withLock { _result } }
        set { lock.withLock { _result = newValue } }
    }

    package func inspect(_ directory: URL) async -> RepositoryInfo? {
        lock.withLock {
            _inspected.append(directory)
            return _result
        }
    }
}
