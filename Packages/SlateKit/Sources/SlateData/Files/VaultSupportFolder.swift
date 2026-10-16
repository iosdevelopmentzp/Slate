import Foundation
import SlateDomain

package enum VaultSupportFolder {
    package static func url(for vault: URL) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let identifier = VaultIdentityPolicy.identifier(forStandardizedPath: standardizedPath(of: vault))
        return base.appendingPathComponent("Slate", isDirectory: true).appendingPathComponent(identifier, isDirectory: true)
    }

    package static func standardizedPath(of vault: URL) -> String {
        vault.standardizedFileURL.resolvingSymlinksInPath().path
    }
}
