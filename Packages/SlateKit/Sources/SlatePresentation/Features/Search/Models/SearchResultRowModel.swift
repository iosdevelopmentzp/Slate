import Foundation
import SlateDomain

struct SearchResultRowModel: Identifiable, Hashable {
    let id: NoteID
    let title: AttributedString
    let excerpt: AttributedString
    let folder: String?
    let date: String

    static let preview = SearchResultRowModel(
        id: NoteID(rawValue: "preview"),
        title: SearchResultMapper.highlighted("Trip to the coast", words: ["coast"]),
        excerpt: SearchResultMapper.highlighted("…book the room near the coast before the end of May…", words: ["coast"]),
        folder: "Notes",
        date: "Oct 3"
    )
}
