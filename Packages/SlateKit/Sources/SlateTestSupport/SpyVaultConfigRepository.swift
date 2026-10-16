import Foundation
import SlateDomain

package final class SpyVaultConfigRepository: VaultConfigRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case spaces
        case saveSpaces([SpaceName])
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _config = SpacesConfig.defaults
    private var _types = NoteType.builtIn
    private var _spacesError: TestError?

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var config: SpacesConfig {
        get { lock.withLock { _config } }
        set { lock.withLock { _config = newValue } }
    }

    package var spacesError: TestError? {
        get { lock.withLock { _spacesError } }
        set { lock.withLock { _spacesError = newValue } }
    }

    package func spaces() async throws -> SpacesConfig {
        try lock.withLock {
            _calls.append(.spaces)
            if let _spacesError { throw _spacesError }
            return _config
        }
    }

    package func saveSpaces(_ config: SpacesConfig) async throws {
        lock.withLock {
            _calls.append(.saveSpaces(config.spaces.map(\.folder)))
            _config = config
        }
    }

    package func types() async throws -> [NoteType] {
        lock.withLock { _types }
    }

    package func ensureDefaults() async throws {}
}
