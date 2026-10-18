import Foundation
import SlateUI

struct VersionRowModel: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let isNamed: Bool
    let badge: TagModel?

    static let preview = VersionRowModel(id: "a1b2c3d", title: "before refactor", detail: "Oct 18, 2026 at 10:02", isNamed: true, badge: nil)
}
