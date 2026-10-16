import Foundation

package struct VaultPath: Hashable, Sendable, Codable {
    package let rawValue: String

    package init(rawValue: String) {
        self.rawValue = rawValue
    }

    package var components: [String] {
        rawValue.split(separator: "/").map(String.init)
    }

    package var space: SpaceName? {
        guard components.count > 1, let first = components.first else { return nil }
        return SpaceName(rawValue: first)
    }

    package var stem: String {
        let name = components.last ?? rawValue
        guard name.hasSuffix(".md") else { return name }
        return String(name.dropLast(3))
    }
}
