import Foundation

package protocol SecretStore: Sendable {
    func secret(for key: String) async -> String?
    func setSecret(_ value: String, for key: String) async throws
    func removeSecret(for key: String) async throws
}
