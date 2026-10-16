import Foundation
import SlateDomain

struct MockTemplateRepository: TemplateRepository {
    func body(for type: String) async throws -> String {
        BuiltInTemplates.bodies[type] ?? ""
    }

    func ensureDefaults() async throws {}
}
