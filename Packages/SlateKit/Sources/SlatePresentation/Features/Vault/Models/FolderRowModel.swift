import Foundation
import SlateDomain
import SlateUI

struct FolderRowModel: Identifiable, Hashable {
    let id: FolderPath
    let title: String
    let icon: String
    let tint: Tint
    let color: SpaceColor
    let count: Int
    let canDelete: Bool
    let deleteQuestion: String
    var isProject = false
    var repository: String?
    var status: TagModel?
    var ticket: String?
    var statusRank = 2

    var space: SpaceName {
        id.space
    }

    var isSpace: Bool {
        id.isSpace
    }

    static let preview = FolderRowModel(
        id: FolderPath(rawValue: "Ideas"),
        title: "Ideas",
        icon: "lightbulb.fill",
        tint: .yellow,
        color: .yellow,
        count: 4,
        canDelete: true,
        deleteQuestion: "Delete \u{201C}Ideas\u{201D}? Its 4 notes move to Notes."
    )

    static let taskPreview: FolderRowModel = {
        var model = FolderRowModel(
            id: FolderPath(rawValue: "MyApp/ABC-123 Fix login"),
            title: "ABC-123 Fix login",
            icon: "folder",
            tint: .blue,
            color: .blue,
            count: 3,
            canDelete: true,
            deleteQuestion: "Delete \u{201C}ABC-123 Fix login\u{201D}? Its 3 notes move to MyApp."
        )
        model.status = TagModel("In progress", tint: .blue)
        model.ticket = "ABC-123"
        model.statusRank = 0
        return model
    }()
}
