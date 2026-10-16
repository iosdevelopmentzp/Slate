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
}
