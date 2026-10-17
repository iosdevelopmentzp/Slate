import Foundation
import SlateDomain

extension Ports {
    package static func live(root: URL, support: URL, keyValues: any KeyValueStore, recorder: any CommandRecording) throws -> Ports {
        let ownWrites = OwnWrites()
        let shell = ShellRunner(recorder: recorder)
        let indexURL = support.appendingPathComponent("index.sqlite")
        let secrets = KeychainSecretStore(service: "local.slate.app")
        let index = try GRDBSearchIndex.open(at: indexURL, vaultPath: VaultSupportFolder.standardizedPath(of: root))
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
            workspace: WorkspaceOpener(),
            loginItem: LoginItemService(),
            system: SystemChecks(root: root, indexURL: indexURL, shell: shell),
            history: GitHistoryRepository(shell: shell, gitDirectory: support.appendingPathComponent("history.git", isDirectory: true), workTree: root),
            journal: FileJournalStore(folder: support.appendingPathComponent("journal", isDirectory: true)),
            actions: ShellActionRunner(shell: shell),
            exporter: NoteExporter(),
            secrets: secrets,
            tracker: JiraIssueClient(keyValues: keyValues, secrets: secrets, session: URLSession.shared),
            agentChanges: FileAgentChangeLog(url: support.appendingPathComponent(FileAgentChangeLog.fileName))
        )
    }
}
