import Foundation
import SlateDomain

struct FileRowModel: Identifiable, Hashable {
    let id: VaultPath
    let name: String
    let detail: String
    let isImage: Bool

    static let preview = FileRowModel(
        id: VaultPath(rawValue: "MyApp/ABC-123 Fix login/crash.log"),
        name: "crash.log",
        detail: "12 KB · 5 min. ago",
        isImage: false
    )
}
