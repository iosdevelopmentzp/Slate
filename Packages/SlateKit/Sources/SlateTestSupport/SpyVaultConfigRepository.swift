import Foundation
import SlateDomain

package final class SpyVaultConfigRepository: VaultConfigRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case spaces
        case saveSpaces([SpaceName])
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _config = SpacesConfig.sixFolders
    private var _types = NoteType.builtIn
    private var _spacesError: TestError?
    private var _patterns: [LinkPattern] = []
    private var _views = SmartView.defaults
    private var _actions: [ActionDefinition] = []
    private var _permissions = AgentPermissions()

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

    package var patterns: [LinkPattern] {
        get { lock.withLock { _patterns } }
        set { lock.withLock { _patterns = newValue } }
    }

    package func linkPatterns() async throws -> [LinkPattern] {
        lock.withLock { _patterns }
    }

    package func saveLinkPatterns(_ patterns: [LinkPattern]) async throws {
        lock.withLock { _patterns = patterns }
    }

    package var actionList: [ActionDefinition] {
        get { lock.withLock { _actions } }
        set { lock.withLock { _actions = newValue } }
    }

    package var permissions: AgentPermissions {
        get { lock.withLock { _permissions } }
        set { lock.withLock { _permissions = newValue } }
    }

    package func agentPermissions() async throws -> AgentPermissions {
        lock.withLock { _permissions }
    }

    package func saveAgentPermissions(_ permissions: AgentPermissions) async throws {
        lock.withLock { _permissions = permissions }
    }

    package func views() async throws -> [SmartView] {
        lock.withLock { _views }
    }

    package func actions() async throws -> [ActionDefinition] {
        lock.withLock { _actions }
    }
}
