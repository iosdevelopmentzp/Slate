import Foundation
import SlateDomain

package final class SpySearchIndex: SearchIndex, @unchecked Sendable {
    package enum Call: Hashable {
        case summaries(space: SpaceName?)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _summariesResult: [NoteSummary] = []
    private var _summariesError: TestError?

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var summariesResult: [NoteSummary] {
        get { lock.withLock { _summariesResult } }
        set { lock.withLock { _summariesResult = newValue } }
    }

    package var summariesError: TestError? {
        get { lock.withLock { _summariesError } }
        set { lock.withLock { _summariesError = newValue } }
    }

    package func summaries(space: SpaceName?) async throws -> [NoteSummary] {
        try lock.withLock {
            _calls.append(.summaries(space: space))
            if let _summariesError { throw _summariesError }
            return _summariesResult
        }
    }
}
