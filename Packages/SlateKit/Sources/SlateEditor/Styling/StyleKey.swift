import Foundation

struct StyleKey: Hashable {
    let kind: BlockKind
    let indent: Int
    var callout = 0
}
