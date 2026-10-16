import CryptoKit
import Foundation

package enum VaultIdentityPolicy {
    package static func identifier(forStandardizedPath path: String) -> String {
        let digest = SHA256.hash(data: Data(path.utf8))
        return String(digest.map { String(format: "%02x", $0) }.joined().prefix(12))
    }
}
