import Foundation

struct ListFamily {
    enum Kind: Equatable {
        case bullets
        case numbers
    }

    let kind: Kind
    let alternate: Bool

    init(kind: Kind, alternate: Bool) {
        self.kind = kind
        self.alternate = alternate
    }

    static func family(of kind: BlockKind) -> Kind {
        kind == .numbered ? .numbers : .bullets
    }
}
