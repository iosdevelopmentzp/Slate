import Foundation
import SlateDomain
import SlateUI

struct SearchResultRowModel: Identifiable, Hashable {
    let id: NoteID
    let title: AttributedString
    let snippet: AttributedString
    let folder: String?
    let date: String
    let typeIcon: String?
    let badges: [TagModel]

    static let preview = SearchResultRowModel(
        id: NoteID(rawValue: "preview"),
        title: SearchResultMapper.highlighted("Retain cycle in the audio engine", words: ["retain"]),
        snippet: SearchResultMapper.highlighted("…the delegate keeps a strong reference, so the retain cycle never breaks…", words: ["retain"]),
        folder: "Tasks",
        date: "Oct 3",
        typeIcon: "checkmark.circle",
        badges: [TagModel("ABC-123", tint: .blue, systemImage: "ticket")]
    )
}
