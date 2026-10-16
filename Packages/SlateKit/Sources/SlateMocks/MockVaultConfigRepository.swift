import Foundation
import SlateDomain

actor MockVaultConfigRepository: VaultConfigRepository {
    private var config: SpacesConfig

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
}
