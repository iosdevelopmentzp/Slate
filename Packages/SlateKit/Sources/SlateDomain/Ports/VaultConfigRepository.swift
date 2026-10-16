import Foundation

package protocol VaultConfigRepository: Sendable {
    func spaces() async throws -> SpacesConfig
    func saveSpaces(_ config: SpacesConfig) async throws
    func types() async throws -> [NoteType]
    func ensureDefaults() async throws
    func linkPatterns() async throws -> [LinkPattern]
    func saveLinkPatterns(_ patterns: [LinkPattern]) async throws
}
