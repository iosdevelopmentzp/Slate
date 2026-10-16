import Foundation
import SlateDomain

extension Ports {
    @MainActor
    package static func live(root: URL, support: URL, keyValues: any KeyValueStore, recorder: any CommandRecording) throws -> Ports {
        let ownWrites = OwnWrites()
        let shell = ShellRunner(recorder: recorder)
        let index = try GRDBSearchIndex.open(at: support.appendingPathComponent("index.sqlite"), vaultPath: VaultSupportFolder.standardizedPath(of: root))
        return Ports(
            keyValues: keyValues,
            files: FileVaultStore(root: root, ownWrites: ownWrites),
            index: index,
            builder: IndexedNoteBuilder(),
            watcher: FSEventsVaultWatcher(root: root, ownWrites: ownWrites),
            trash: FileTrashRepository(root: root),
            templates: FileTemplateRepository(root: root),
            config: FileVaultConfigRepository(root: root),
            clock: SystemClock(),
            attachments: FileAttachmentStore(root: root),
            capture: ScreencaptureTool(shell: shell),
            workspace: WorkspaceOpener(quickLookSource: QuickLookSource())
        )
    }
}
