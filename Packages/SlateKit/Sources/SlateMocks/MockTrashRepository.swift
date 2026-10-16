import Foundation
import SlateDomain

actor MockTrashRepository: TrashRepository {
    private var trashed: [TrashItem] = [
        TrashItem(
            path: VaultPath(rawValue: "Inbox/Old meeting notes.md"),
            originalPath: VaultPath(rawValue: "Inbox/Old meeting notes.md"),
            trashedAt: MockVault.reference.addingTimeInterval(-86_400 * 3)
        ),
    ]

    func trash(_ path: VaultPath, at date: Date) -> TrashItem {
        let item = TrashItem(path: path, originalPath: path, trashedAt: date)
        trashed.append(item)
        return item
    }

    func restore(_ item: TrashItem) -> VaultPath {
        trashed.removeAll { $0.path == item.path }
        return item.originalPath
    }

    func delete(_ item: TrashItem) {
        trashed.removeAll { $0.path == item.path }
    }

    func items() -> [TrashItem] {
        trashed
    }
}
