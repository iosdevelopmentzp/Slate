import Foundation
import SlateDomain
import SlateUI

struct TaskLineModel: Hashable {
    let status: NoteStatus
    let statusTag: TagModel
    let ticket: String?
    let branch: String?

    static let preview = TaskLineModel(status: .active, statusTag: TagModel("In progress", tint: .blue), ticket: "ABC-123", branch: "feature/ABC-123-fix-login")
}
