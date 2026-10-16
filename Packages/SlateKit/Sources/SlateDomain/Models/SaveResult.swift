import Foundation

package enum SaveResult: Hashable, Sendable {
    case unchanged(NoteDocument)
    case saved(NoteDocument)
    case conflict(diskHash: ContentHash?)

    package var document: NoteDocument? {
        switch self {
        case .unchanged(let document), .saved(let document): document
        case .conflict: nil
        }
    }
}
