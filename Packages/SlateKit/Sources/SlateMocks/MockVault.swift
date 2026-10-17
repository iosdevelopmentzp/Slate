import Foundation
import SlateDomain

package enum MockVault {
    package static let notes = SpaceName(rawValue: "Notes")
    package static let ideas = SpaceName(rawValue: "Ideas")
    package static let work = SpaceName(rawValue: "Work")

    package static let reference = Date(timeIntervalSince1970: 1_792_000_000)

    package static let config = SpacesConfig(spaces: [
        Space(folder: notes, icon: "folder.fill", color: .blue, defaultType: "note"),
        Space(folder: ideas, icon: "lightbulb.fill", color: .yellow, defaultType: "note"),
        Space(folder: work, icon: "briefcase.fill", color: .green, defaultType: "note"),
    ])

    package static var spaces: [Space] {
        config.spaces
    }

    package static var summaries: [NoteSummary] {
        documents.map { MockIndexedNoteBuilder().build($0).summary }
    }

    package static let documents: [NoteDocument] = [
        document(
            "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e01", space: notes, title: "Welcome to Slate", pinned: true, minutesAgo: 2,
            body: "Slate keeps your notes in folders. Each note is a plain text file in your notes folder, so other apps can open it too.\n\n- ⌘N makes a new note in the current folder.\n- ⌃⌥Space writes a quick note from any app.\n- ⌘F searches your notes.\n"
        ),
        document(
            "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e02", space: notes, title: "Books to read", minutesAgo: 300,
            body: "A short list for the summer.\n\n- [ ] The long walk\n- [ ] A history of maps\n- [x] Letters from the coast\n"
        ),
        document(
            "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e03", space: ideas, title: "Garden plan", minutesAgo: 1_440,
            body: "Tomatoes near the fence, herbs by the door.\n\n![](../_attachments/20261015-101500-garden.png)\n"
        ),
        document(
            "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e11", space: work, title: "Weekly plan", minutesAgo: 10,
            body: "## Monday\n\nFinish the draft and send it for review.\n\n- [x] Draft\n- [ ] Review\n- [ ] Send\n"
        ),
        document(
            "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e12", space: work, title: "Questions for the team", minutesAgo: 2_880,
            body: "What should the next release include? Who can help with the screenshots?\n"
        ),
        document(
            "0b6c1f7e-2a3d-4c5e-8f90-1a2b3c4d5e13", space: work, subfolder: "Clients", title: "Call notes", minutesAgo: 4_320,
            body: "Agreed on the new dates. Send the summary on Friday.\n"
        ),
    ]

    private static func document(
        _ id: String,
        space: SpaceName,
        subfolder: String? = nil,
        title: String,
        pinned: Bool = false,
        minutesAgo: Double,
        body: String
    ) -> NoteDocument {
        let date = reference.addingTimeInterval(-minutesAgo * 60)
        var header = HeaderDefaultsPolicy.header(id: NoteID(rawValue: id), title: title, type: .note, now: date)
        header.pinned = pinned ? true : nil
        let folder = subfolder.map { FolderPath(space: space).appending($0) } ?? FolderPath(space: space)
        let path = VaultPath(folder: folder, stem: StemPolicy.stem(forTitle: title))
        let data = NoteCodec.encode(header: header, body: body, opaqueHeader: nil, timeZone: .gmt)
        return NoteDocument(
            path: path,
            header: header,
            body: body,
            hash: .of(data),
            meta: FileMeta(path: path, created: date, modified: date, size: data.count)
        )
    }
}
