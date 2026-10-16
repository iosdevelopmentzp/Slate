import Foundation

package enum HeaderDefaultsPolicy {

    package static func header(id: NoteID, title: String, type: NoteType, now: Date) -> NoteHeader {
        NoteHeader(
            id: id,
            title: title,
            type: type.name,
            created: now,
            updated: now,
            status: type.hasStatus ? NoteStatus.todo.rawValue : nil
        )
    }

    package static func type(named name: String?, space: Space?, among types: [NoteType]) -> NoteType {
        let wanted = name ?? space?.defaultType ?? NoteType.defaultName
        return types.first { $0.name == wanted } ?? NoteType.builtIn.first { $0.name == wanted } ?? .note
    }

    package static func space(for type: NoteType, requested: SpaceName?, config: SpacesConfig) -> SpaceName {
        if let requested { return requested }
        if let preferred = type.defaultSpace, config.space(preferred) != nil { return preferred }
        return config.captureSpace
    }
}
