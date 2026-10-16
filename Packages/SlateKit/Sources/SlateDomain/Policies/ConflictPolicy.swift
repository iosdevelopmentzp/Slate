import Foundation

package enum ConflictPolicy {
    package enum Decision: Hashable, Sendable {
        case ignore
        case reload
        case adoptHeader
        case conflict
    }

    package static func decide(loaded: NoteDocument, disk: NoteDocument, isDirty: Bool) -> Decision {
        if disk.hash == loaded.hash { return .ignore }
        if isDirty == false { return .reload }
        if disk.body == loaded.body { return .adoptHeader }
        return .conflict
    }
}
