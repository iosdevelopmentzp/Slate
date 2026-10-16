import Foundation

package protocol VaultConfigRepository: Sendable {
    func spaces() async throws -> [Space]
}
