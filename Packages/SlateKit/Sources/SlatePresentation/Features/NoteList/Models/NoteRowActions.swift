import Foundation
import SlateDomain

struct NoteRowActions {
    let moveTargets: [MoveTargetModel]
    let pin: () -> Void
    let move: (FolderPath) -> Void
    let duplicate: () -> Void
    let requestTrash: () -> Void
    let copyPath: () -> Void
    let copyLink: () -> Void
    let drag: () -> NSItemProvider

    static let preview = NoteRowActions(moveTargets: [], pin: {}, move: { _ in }, duplicate: {}, requestTrash: {}, copyPath: {}, copyLink: {}, drag: { NSItemProvider() })
}
