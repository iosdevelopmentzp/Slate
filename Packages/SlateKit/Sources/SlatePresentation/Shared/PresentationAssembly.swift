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
    let search: SearchStore
    let settings: SettingsStore
    let capture: CaptureStore
    let daily: DailyStore
    let history: HistoryStore

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
            templates: ports.templates,
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
        search = SearchStore(index: ports.index, notes: noteList, navigator: navigator, clock: ports.clock, activity: activity, events: events)
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
            toaster: toaster,
            create: useCases.create,
            templates: ports.templates,
            journal: ports.journal
        )
        settings = SettingsStore(
            store: ports.keyValues,
            config: ports.config,
            loginItem: ports.loginItem,
            system: ports.system,
            index: ports.index,
            reindex: useCases.reindex,
            vaultPath: vaultRoot.path,
            activity: activity,
            events: events
        )
        capture = CaptureStore(capture: useCases.capture, config: ports.config, store: ports.keyValues, navigator: navigator, toaster: toaster, activity: activity, events: events)
        history = HistoryStore(
            history: ports.history,
            snapshot: useCases.snapshot,
            restoreVersion: useCases.restoreVersion,
            purgeTrash: useCases.purgeTrash,
            store: ports.keyValues,
            activity: activity,
            toaster: toaster,
            events: events
        )
        daily = DailyStore(ensureDaily: useCases.ensureDaily, notes: noteList, navigator: navigator, clock: ports.clock, activity: activity, events: events)
    }

    package func start() {
        feed.start()
        history.start()
        Task {
            await vault.refresh()
            await search.refreshTags()
        }
    }

    package func stop() {
        feed.stop()
        history.stop()
    }

    package func flush() async {
        await editor.flush()
    }

    package func pendingSave() -> (@Sendable () async -> Void)? {
        let save = editor.pendingSave()
        let snapshot = history.quitJob()
        guard save != nil || snapshot != nil else { return nil }
        return {
            await save?()
            await snapshot?()
        }
    }
}
