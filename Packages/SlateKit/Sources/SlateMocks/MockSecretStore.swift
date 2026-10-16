import Foundation
import SlateDomain

struct MockSecretStore: SecretStore {
    func secret(for key: String) async -> String? {
        nil
    }

    func setSecret(_ value: String, for key: String) async throws {}

    func removeSecret(for key: String) async throws {}
}
