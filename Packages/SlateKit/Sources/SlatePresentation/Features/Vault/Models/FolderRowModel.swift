import Foundation
import SlateDomain
import SlateUI

struct FolderRowModel: Identifiable, Hashable {
    let id: SpaceName
    let title: String
    let icon: String
    let tint: Tint
    let color: SpaceColor
    let count: Int
    let canDelete: Bool
    let deleteQuestion: String

    static let preview = FolderRowModel(
        id: SpaceName(rawValue: "Ideas"),
        title: "Ideas",
        icon: "lightbulb.fill",
        tint: .yellow,
        color: .yellow,
        count: 4,
        canDelete: true,
        deleteQuestion: "Delete \u{201C}Ideas\u{201D}? Its 4 notes move to Notes."
    )
}
