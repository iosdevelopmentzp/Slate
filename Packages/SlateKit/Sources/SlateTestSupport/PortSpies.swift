import SlateDomain

package struct PortSpies: Sendable {
    package let files = SpyVaultFileStore()
    package let index = SpySearchIndex()
    package let builder = SpyIndexedNoteBuilder()
    package let watcher = SpyVaultWatcher()
    package let trash: SpyTrashRepository
    package let templates = SpyTemplateRepository()
    package let config = SpyVaultConfigRepository()
    package let clock = SpyClock()
    package let attachments = SpyAttachmentStore()
    package let capture: SpyScreenCapture
    package let workspace = SpyWorkspace()
    package let loginItem = SpyLoginItem()
    package let system = SpySystemChecks()
    package let history = SpyHistoryRepository()
    package let journal = SpyJournalStore()
    package let actions = SpyActionRunner()
    package let exporter = SpyExporter()
    package let secrets = SpySecretStore()
    package let tracker = SpyIssueTracker()
    package let agentChanges = SpyAgentChangeLog()

    package init() {
        trash = SpyTrashRepository(files: files)
        capture = SpyScreenCapture(attachments: attachments)
    }
}
