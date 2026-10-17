import Foundation
import SlateDomain

actor MockVaultConfigRepository: VaultConfigRepository {
    private var config: SpacesConfig
    private var permissions = AgentPermissions()

    init(config: SpacesConfig = MockVault.config) {
        self.config = config
    }

    func spaces() -> SpacesConfig {
        config
    }

    func saveSpaces(_ config: SpacesConfig) {
        self.config = config
    }

    func types() -> [NoteType] {
        NoteType.builtIn
    }

    func ensureDefaults() {}

    func linkPatterns() -> [LinkPattern] {
        LinkPatternPolicy.defaults(for: TrackerSettings(trackerBaseURL: "https://example.atlassian.net", gitHostBaseURL: "https://gitlab.example.com", gitProjectPath: "group/project"))
    }

    func saveLinkPatterns(_ patterns: [LinkPattern]) {}

    func views() -> [SmartView] {
        SmartView.defaults
    }

    func agentPermissions() -> AgentPermissions {
        permissions
    }

    func saveAgentPermissions(_ permissions: AgentPermissions) {
        self.permissions = permissions
    }

    func actions() -> [ActionDefinition] {
        [ActionDefinition(id: "copy-branch", title: "Copy the branch name", icon: "arrow.branch", command: "printf %s \"$SLATE_BRANCH\"", condition: .hasBranch, output: .clipboard)]
    }
}
