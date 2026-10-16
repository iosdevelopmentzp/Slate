import Foundation
import SlateDomain

package final class SpySecretStore: SecretStore, @unchecked Sendable {
    private let lock = NSLock()
    private var _values: [String: String] = [:]

    package init() {}

    package var values: [String: String] {
        lock.withLock { _values }
    }

    package func secret(for key: String) async -> String? {
        lock.withLock { _values[key] }
    }

    package func setSecret(_ value: String, for key: String) async throws {
        lock.withLock { _values[key] = value }
    }

    package func removeSecret(for key: String) async throws {
        lock.withLock { _values[key] = nil }
    }
}
