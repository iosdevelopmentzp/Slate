import Foundation
import SlateDomain
import SlateUI

@MainActor
package final class PresentationAssembly {
    let events: AppEvents
    let navigator: Navigator
    package let activity: ActivityLog
    let toaster: Toaster
    let hints: HintCenter
    let layout: WindowLayout
    let feed: VaultChangeFeed
    let vault: VaultStore
    let noteList: NoteListStore
    let editor: EditorStore
    let panelVisibility: PanelVisibility

    package init(ports: Ports, useCases: UseCases, activity: ActivityLog, vaultRoot: URL) {
        events = AppEvents()
        navigator = Navigator(store: ports.keyValues)
        self.activity = activity
        toaster = Toaster(write: PasteboardWriter.write)
        hints = HintCenter()
        panelVisibility = PanelVisibility()
        layout = WindowLayout(store: ports.keyValues)
        feed = VaultChangeFeed(watcher: ports.watcher, reindex: useCases.reindex, activity: activity, events: events)
        vault = VaultStore(
            config: ports.config,
            createSpace: useCases.createSpace,
            renameSpace: useCases.renameSpace,
            navigator: navigator,
            activity: activity,
            events: events
        )
        noteList = NoteListStore(
            index: ports.index,
            trash: ports.trash,
            create: useCases.create,
            updateHeader: useCases.updateHeader,
            move: useCases.move,
            archive: useCases.archive,
            duplicate: useCases.duplicate,
            trashNote: useCases.trash,
            restore: useCases.restore,
            navigator: navigator,
            toaster: toaster,
            activity: activity,
            events: events,
            store: ports.keyValues
        )
        editor = EditorStore(
            files: ports.files,
            index: ports.index,
            save: useCases.save,
            rename: useCases.rename,
            navigator: navigator,
            activity: activity,
            events: events,
            clock: ports.clock,
            importAttachment: useCases.importAttachment,
            attachScreenshot: useCases.attachScreenshot,
            workspace: ports.workspace,
            vaultRoot: vaultRoot,
            panel: panelVisibility,
            toaster: toaster
        )
    }

    package func start() {
        feed.start()
        Task {
            await vault.refresh()
        }
    }

    package func flush() async {
        await editor.flush()
    }

    package func pendingSave() -> (@Sendable () async -> Void)? {
        editor.pendingSave()
    }
}
