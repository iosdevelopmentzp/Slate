import Foundation
import SlateDomain

package final class SpyTemplateRepository: TemplateRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var _bodies = BuiltInTemplates.bodies

    package init() {}

    package var bodies: [String: String] {
        get { lock.withLock { _bodies } }
        set { lock.withLock { _bodies = newValue } }
    }

    package func body(for type: String) async throws -> String {
        lock.withLock { _bodies[type] ?? "" }
    }

    package func ensureDefaults() async throws {}

    package func names() async throws -> [String] {
        lock.withLock { _bodies.keys.sorted() }
    }
}
