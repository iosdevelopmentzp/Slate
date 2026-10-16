import Foundation
import SlateDomain

extension Ports {
    package static func live(root: URL, keyValues: any KeyValueStore) -> Ports {
        let ownWrites = OwnWrites()
        return Ports(
            keyValues: keyValues,
            files: FileVaultStore(root: root, ownWrites: ownWrites),
            index: MemorySearchIndex(),
            builder: IndexedNoteBuilder(),
            watcher: FSEventsVaultWatcher(root: root, ownWrites: ownWrites),
            trash: FileTrashRepository(root: root),
            templates: FileTemplateRepository(root: root),
            config: FileVaultConfigRepository(root: root),
            clock: SystemClock()
        )
    }
}
