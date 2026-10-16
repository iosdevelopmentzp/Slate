import Foundation

package protocol TemplateRepository: Sendable {
    func body(for type: String) async throws -> String
    func ensureDefaults() async throws
    func names() async throws -> [String]
}
