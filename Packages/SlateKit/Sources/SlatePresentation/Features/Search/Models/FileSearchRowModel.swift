import Foundation
import SlateDomain

struct FileSearchRowModel: Identifiable, Hashable {
    let id: VaultPath
    let name: AttributedString
    let excerpt: AttributedString
    let folder: String

    static let preview = FileSearchRowModel(
        id: VaultPath(rawValue: "MyApp/ABC-123 Fix login/crash.log"),
        name: SearchResultMapper.highlighted("crash.log", words: ["crash"]),
        excerpt: SearchResultMapper.highlighted("…Fatal error: unexpectedly found nil while unwrapping…", words: ["fatal"]),
        folder: "MyApp/ABC-123 Fix login"
    )
}
