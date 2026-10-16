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
    let noteList: NoteListStore

    package init(ports: Ports, useCases: UseCases, activity: ActivityLog) {
        events = AppEvents()
        navigator = Navigator(store: ports.keyValues)
        self.activity = activity
        toaster = Toaster(write: PasteboardWriter.write)
        hints = HintCenter()
        layout = WindowLayout(store: ports.keyValues)
        noteList = NoteListStore(
            index: ports.index,
            config: ports.config,
            navigator: navigator,
            activity: activity,
            events: events
        )
    }
}
