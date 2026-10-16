import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class SearchStore {
    static let debounce: Duration = .milliseconds(80)
    static let limit = 100

    var query = "" {
        didSet {
            guard query != oldValue else { return }
            run()
        }
    }
    private(set) var results: [SearchHit] = []
    private(set) var isSearching = false
    private(set) var parsed = SearchQuery()
    private(set) var scope: SpaceName?

    @ObservationIgnored private let index: any SearchIndex
    @ObservationIgnored private let notes: any NoteLookup
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let clock: any Clock
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(index: any SearchIndex, notes: any NoteLookup, navigator: Navigator, clock: any Clock, activity: ActivityLog, events: AppEvents) {
        self.index = index
        self.notes = notes
        self.navigator = navigator
        self.clock = clock
        self.activity = activity
        self.events = events
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            handle(event)
        }
    }

    var isActive: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var words: [String] {
        parsed.words
    }

    var scopeName: String? {
        scope?.rawValue
    }

    func clear() {
        query = ""
    }

    func searchAllNotes() {
        navigator.show(.all)
        run()
    }

    func revealMatch(_ id: NoteID, words: [String]) {
        events.post(.searchOpened(id, words: words))
    }

    func open(_ hit: SearchHit) {
        navigator.select(hit.id)
        events.post(.searchOpened(hit.id, words: words))
    }

    func openFirst() {
        guard let first = results.first else { return }
        open(first)
    }

    func waitForResults() async {
        await task?.value
    }

    private func run() {
        task?.cancel()
        guard isActive else {
            parsed = SearchQuery()
            scope = nil
            results = []
            isSearching = false
            return
        }
        var scoped = SearchQueryParser.parse(query, now: clock.now(), timeZone: clock.timeZone)
        scope = scopeSpace(for: scoped)
        if let scope {
            scoped.filters.append(.space(scope.rawValue))
        }
        parsed = scoped
        results = titleMatches(for: scoped)
        isSearching = true
        let query = scoped
        task = Task { [weak self] in
            try? await Task.sleep(for: Self.debounce)
            guard Task.isCancelled == false, let self else { return }
            do {
                let hits = try await index.search(query, limit: Self.limit)
                guard Task.isCancelled == false else { return }
                results = hits
            } catch {
                activity.log("Search failed", detail: error.localizedDescription, outcome: .failure)
            }
            isSearching = false
        }
    }

    private func scopeSpace(for query: SearchQuery) -> SpaceName? {
        let hasSpace = query.filters.contains { if case .space = $0 { true } else { false } }
        return hasSpace ? nil : navigator.space
    }

    private func titleMatches(for query: SearchQuery) -> [SearchHit] {
        guard query.hasText, query.filters.allSatisfy({ if case .space = $0 { true } else { false } }) else { return [] }
        let space = navigator.space
        let words = query.words.map { $0.lowercased() }
        let matching = notes.summaries.filter { summary in
            if let space, summary.space != space { return false }
            let title = summary.title.lowercased()
            return words.allSatisfy { title.contains($0) }
        }
        let hits = matching.map { SearchHit(summary: $0, excerpt: $0.preview, rank: 0) }
        return Array(SearchMatchPolicy.sorted(hits, words: query.words).prefix(Self.limit))
    }

    private func handle(_ event: AppEvent) {
        switch event {
        case .indexUpdated, .noteSaved:
            if isActive { run() }
        default:
            break
        }
    }
}
