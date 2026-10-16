import Foundation
import SlateUI

struct NoteChip: Hashable {
    enum Kind: Hashable {
        case type
        case ticket(String)
        case branch(String)
        case mergeRequest(String)
        case status
        case folder
        case details
    }

    let kind: Kind
    let model: TagModel
}
