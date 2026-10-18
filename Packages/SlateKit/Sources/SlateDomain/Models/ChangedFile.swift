import Foundation

package struct ChangedFile: Hashable, Sendable {
    package enum Kind: String, Hashable, Sendable {
        case added
        case changed
        case removed
    }

    package let path: VaultPath
    package let kind: Kind

    package init(path: VaultPath, kind: Kind) {
        self.path = path
        self.kind = kind
    }
}
