import CryptoKit
import Foundation

package struct ContentHash: Hashable, Sendable, Codable {
    package let rawValue: String

    package init(rawValue: String) {
        self.rawValue = rawValue
    }

    package static func of(_ data: Data) -> ContentHash {
        ContentHash(rawValue: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined())
    }
}
