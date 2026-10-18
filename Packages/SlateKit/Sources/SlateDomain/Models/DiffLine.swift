import Foundation

package struct DiffLine: Hashable, Sendable {
    package enum Kind: Hashable, Sendable {
        case same
        case added
        case removed
    }

    package let kind: Kind
    package let text: String

    package init(_ kind: Kind, _ text: String) {
        self.kind = kind
        self.text = text
    }
}
