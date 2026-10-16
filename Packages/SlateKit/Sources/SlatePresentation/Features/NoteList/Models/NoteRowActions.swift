import Foundation
import SlateDomain

struct NoteRowActions {
    let moveTargets: [Space]
    let pin: () -> Void
    let move: (SpaceName) -> Void
    let duplicate: () -> Void
    let requestTrash: () -> Void

    static let preview = NoteRowActions(moveTargets: [], pin: {}, move: { _ in }, duplicate: {}, requestTrash: {})
}
