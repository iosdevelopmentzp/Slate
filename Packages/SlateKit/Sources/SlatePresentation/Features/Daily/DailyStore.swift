import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class DailyStore {
    @ObservationIgnored private let ensureDaily: EnsureDailyNoteUseCase
    @ObservationIgnored private let notes: any NoteLookup
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let clock: any Clock
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents

    init(ensureDaily: EnsureDailyNoteUseCase, notes: any NoteLookup, navigator: Navigator, clock: any Clock, activity: ActivityLog, events: AppEvents) {
        self.ensureDaily = ensureDaily
        self.notes = notes
        self.navigator = navigator
        self.clock = clock
        self.activity = activity
        self.events = events
    }

    var currentStem: String? {
        guard let id = navigator.selectedNote, let summary = notes.summaries.first(where: { $0.id == id }),
              summary.type == NoteType.daily.name, DailyPolicy.isDailyStem(summary.stem) else { return nil }
        return summary.stem
    }

    func openToday() async {
        await open(stem: nil)
    }

    func openDay(_ offset: Int) async {
        guard let current = currentStem, let stem = DailyPolicy.day(offset, from: current, timeZone: clock.timeZone) else { return }
        await open(stem: stem)
    }

    private func open(stem: String?) async {
        do {
            let daily = try await ensureDaily.execute(stem: stem)
            if daily.wasCreated {
                events.post(.indexUpdated)
                events.post(.noteCreated(daily.document.id, caret: daily.caret))
            }
            navigator.select(daily.document.id)
        } catch {
            activity.log("Cannot open the daily note", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
