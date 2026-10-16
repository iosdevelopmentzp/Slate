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
    package let attachments: any AttachmentStore
    package let capture: any ScreenCapturing
    package let workspace: any WorkspaceOpening
    package let loginItem: any LaunchAtLogin
    package let system: any SystemChecking
    package let history: any HistoryRepository
    package let journal: any JournalStore
    package let actions: any ActionRunning
    package let exporter: any NoteExporting

    package init(
        keyValues: any KeyValueStore,
        files: any VaultFileStore,
        index: any SearchIndex,
        builder: any IndexedNoteBuilding,
        watcher: any VaultWatching,
        trash: any TrashRepository,
        templates: any TemplateRepository,
        config: any VaultConfigRepository,
        clock: any Clock,
        attachments: any AttachmentStore,
        capture: any ScreenCapturing,
        workspace: any WorkspaceOpening,
        loginItem: any LaunchAtLogin,
        system: any SystemChecking,
        history: any HistoryRepository,
        journal: any JournalStore,
        actions: any ActionRunning,
        exporter: any NoteExporting
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
        self.attachments = attachments
        self.capture = capture
        self.workspace = workspace
        self.loginItem = loginItem
        self.system = system
        self.history = history
        self.journal = journal
        self.actions = actions
        self.exporter = exporter
    }
}
