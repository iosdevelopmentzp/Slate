import Foundation
import SlateDomain
import SlateUI

enum NoteChipsMapper {

    static func chips(for document: NoteDocument, type: NoteType?) -> [TagModel] {
        var chips: [TagModel] = []
        if document.type != NoteType.defaultName {
            chips.append(TagModel(type?.title ?? document.type.capitalized, tint: .purple, systemImage: type?.icon ?? "doc"))
        }
        if let ticket = document.header.ticket {
            chips.append(TagModel(ticket, tint: .blue, systemImage: "ticket"))
        }
        if let status = document.header.status.flatMap(NoteStatus.init(rawValue:)) {
            chips.append(TagModel(NoteStatusText.title(status), tint: NoteStatusText.tint(status)))
        }
        if let space = document.path.space {
            chips.append(TagModel(space.rawValue, systemImage: "folder"))
        }
        if let subfolder = document.path.subfolder {
            chips.append(TagModel(subfolder, systemImage: "folder"))
        }
        if document.isHeaderOpaque {
            chips.append(TagModel("Details read-only", tint: .orange, systemImage: "lock", hint: "The details at the top of the file use YAML the app does not edit."))
        }
        return chips
    }
}
