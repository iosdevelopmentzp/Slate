import Foundation
import SlateDomain

package final class SpyVaultConfigRepository: VaultConfigRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case spaces
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _spacesResult: [Space] = []
    private var _spacesError: TestError?

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var spacesResult: [Space] {
        get { lock.withLock { _spacesResult } }
        set { lock.withLock { _spacesResult = newValue } }
    }

    package var spacesError: TestError? {
        get { lock.withLock { _spacesError } }
        set { lock.withLock { _spacesError = newValue } }
    }

    package func spaces() async throws -> [Space] {
        try lock.withLock {
            _calls.append(.spaces)
            if let _spacesError { throw _spacesError }
            return _spacesResult
        }
    }
}
