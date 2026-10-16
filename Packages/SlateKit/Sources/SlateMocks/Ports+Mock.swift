import Foundation
import SlateDomain

extension Ports {
    package static func mock(keyValues: any KeyValueStore = InMemoryKeyValueStore()) -> Ports {
        Ports(
            keyValues: keyValues,
            files: MockVaultFileStore(),
            index: MockSearchIndex(),
            builder: MockIndexedNoteBuilder(),
            watcher: MockVaultWatcher(),
            trash: MockTrashRepository(),
            templates: MockTemplateRepository(),
            config: MockVaultConfigRepository(),
            clock: MockClock()
        )
    }
}
