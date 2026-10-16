import Foundation

package struct Ports: Sendable {
    package let keyValues: any KeyValueStore
    package let files: any VaultFileStore
    package let index: any SearchIndex
    package let builder: any IndexedNoteBuilding
    package let watcher: any VaultWatching
    package let trash: any TrashRepository
    package let templates: any TemplateRepository
    package let config: any VaultConfigRepository
    package let clock: any Clock

    package init(
        keyValues: any KeyValueStore,
        files: any VaultFileStore,
        index: any SearchIndex,
        builder: any IndexedNoteBuilding,
        watcher: any VaultWatching,
        trash: any TrashRepository,
        templates: any TemplateRepository,
        config: any VaultConfigRepository,
        clock: any Clock
    ) {
        self.keyValues = keyValues
        self.files = files
        self.index = index
        self.builder = builder
        self.watcher = watcher
        self.trash = trash
        self.templates = templates
        self.config = config
        self.clock = clock
    }
}
