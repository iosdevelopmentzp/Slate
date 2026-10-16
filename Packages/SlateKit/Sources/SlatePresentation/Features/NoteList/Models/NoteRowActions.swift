import Foundation
import SlateDomain

struct NoteRowActions {
    let moveTargets: [Space]
    let canArchive: Bool
    let pin: () -> Void
    let move: (SpaceName) -> Void
    let duplicate: () -> Void
    let archive: () -> Void
    let requestTrash: () -> Void

    static let preview = NoteRowActions(moveTargets: [], canArchive: true, pin: {}, move: { _ in }, duplicate: {}, archive: {}, requestTrash: {})
}
