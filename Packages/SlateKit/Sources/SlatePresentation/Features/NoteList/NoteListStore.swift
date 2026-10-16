import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class NoteListStore {
    var spaces: [Space] = []
    var summaries: [NoteSummary] = []
    var filterText = ""
    private(set) var isLoading = false
    private(set) var failure: String?

    @ObservationIgnored private let index: any SearchIndex
    @ObservationIgnored private let config: any VaultConfigRepository
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(
        index: any SearchIndex,
        config: any VaultConfigRepository,
        navigator: Navigator,
        activity: ActivityLog,
        events: AppEvents
    ) {
        self.index = index
        self.config = config
        self.navigator = navigator
        self.activity = activity
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            handle(event)
        }
    }

    var space: SpaceName? {
        navigator.space
    }

    var visibleNotes: [NoteSummary] {
        let inSpace = summaries.filter { space == nil || $0.space == space }
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching = query.isEmpty ? inSpace : inSpace.filter { $0.title.localizedCaseInsensitiveContains(query) }
        return matching.sorted(by: Self.listOrder)
    }

    var selected: NoteSummary? {
        guard let id = navigator.selectedNote else { return nil }
        return summaries.first { $0.id == id }
    }

    var spaceTitle: String {
        space?.rawValue ?? "All notes"
    }

    func refresh() async {
        isLoading = summaries.isEmpty
        await refreshTask.run { [weak self] in
            guard let self else { return }
            do {
                async let loadedSpaces = config.spaces()
                async let loadedSummaries = index.summaries(space: nil)
                spaces = try await loadedSpaces
                summaries = try await loadedSummaries
                failure = nil
            } catch {
                failure = error.localizedDescription
                activity.log("Cannot read the notes", detail: error.localizedDescription, outcome: .failure)
            }
            isLoading = false
        }
    }

    func show(space: SpaceName?) {
        navigator.show(space: space)
        if let selected, space == nil || selected.space == space {
            return
        }
        navigator.select(visibleNotes.first?.id)
    }

    func select(_ id: NoteID?) {
        navigator.select(id)
    }

    func count(in space: SpaceName?) -> Int {
        guard let space else { return summaries.count }
        return summaries.filter { $0.space == space }.count
    }

    private func handle(_ event: AppEvent) {
        switch event {
        case .indexUpdated, .noteCreated, .noteSaved:
            Task { [weak self] in
                guard let self else { return }
                await refresh()
            }
        }
    }

    private static func listOrder(_ lhs: NoteSummary, _ rhs: NoteSummary) -> Bool {
        if lhs.pinned != rhs.pinned {
            return lhs.pinned
        }
        return lhs.updated > rhs.updated
    }
}
