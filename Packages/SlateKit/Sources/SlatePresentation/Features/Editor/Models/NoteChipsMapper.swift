import Foundation
import SlateDomain
import SlateUI

enum NoteChipsMapper {

    static func chips(for document: NoteDocument, type: NoteType?) -> [TagModel] {
        noteChips(for: document, type: type).map(\.model)
    }

    static func noteChips(for document: NoteDocument, type: NoteType?, ticketURL: String? = nil) -> [NoteChip] {
        var chips: [NoteChip] = []
        if document.type != NoteType.defaultName {
            chips.append(NoteChip(kind: .type, model: TagModel(type?.title ?? document.type.capitalized, tint: .purple, systemImage: type?.icon ?? "doc")))
        }
        if let ticket = document.header.ticket, ticket.isEmpty == false {
            chips.append(NoteChip(kind: .ticket(ticket), model: TagModel(ticket, tint: .blue, systemImage: "ticket", hint: ticketURL ?? "Set the tracker address in Settings → Links to open tickets.")))
        }
        if let branch = document.header.branch, branch.isEmpty == false {
            chips.append(NoteChip(kind: .branch(branch), model: TagModel(branch, tint: .secondary, systemImage: "arrow.branch", hint: "Click to copy the branch name")))
        }
        if let mr = document.header.mr, mr.isEmpty == false {
            chips.append(NoteChip(kind: .mergeRequest(mr), model: TagModel(mr, tint: .orange, systemImage: "arrow.triangle.merge", hint: "Open the merge request")))
        }
        if let status = document.header.status.flatMap(NoteStatus.init(rawValue:)) {
            chips.append(NoteChip(kind: .status, model: TagModel(NoteStatusText.title(status), tint: NoteStatusText.tint(status))))
        }
        if let space = document.path.space {
            chips.append(NoteChip(kind: .folder, model: TagModel(space.rawValue, systemImage: "folder")))
        }
        if let subfolder = document.path.subfolder {
            chips.append(NoteChip(kind: .folder, model: TagModel(subfolder, systemImage: "folder")))
        }
        if document.isHeaderOpaque {
            chips.append(NoteChip(kind: .details, model: TagModel("Details read-only", tint: .orange, systemImage: "lock", hint: "The details at the top of the file use YAML the app does not edit.")))
        }
        return chips
    }
}
