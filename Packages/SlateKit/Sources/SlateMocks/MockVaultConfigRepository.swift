import Foundation
import SlateDomain

package final class MockVaultConfigRepository: VaultConfigRepository {
    private let spaces: [Space]

    package init(spaces: [Space] = MockVault.spaces) {
        self.spaces = spaces
    }

    package func spaces() async throws -> [Space] {
        spaces
    }
}
