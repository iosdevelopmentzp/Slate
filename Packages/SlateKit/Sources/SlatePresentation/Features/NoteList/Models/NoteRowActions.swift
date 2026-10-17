import Foundation
import SlateDomain

struct NoteRowActions {
    let moveTargets: [MoveTargetModel]
    let pin: () -> Void
    let move: (FolderPath) -> Void
    let duplicate: () -> Void
    let requestTrash: () -> Void

    static let preview = NoteRowActions(moveTargets: [], pin: {}, move: { _ in }, duplicate: {}, requestTrash: {})
}
