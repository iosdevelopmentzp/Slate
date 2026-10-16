import Foundation

package struct IndexedLink: Hashable, Sendable {
    package enum Kind: String, Hashable, Sendable {
        case wiki
        case url
    }

    package var kind: Kind
    package var target: String

    package init(kind: Kind, target: String) {
        self.kind = kind
        self.target = target
    }
}
