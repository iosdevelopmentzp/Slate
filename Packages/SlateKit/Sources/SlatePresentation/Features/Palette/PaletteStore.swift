import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class PaletteStore {
    static let noteLimit = 8
    static let commandLimit = 8

    private(set) var isOpen = false
    var query = "" {
        didSet {
            guard query != oldValue else { return }
            selection = 0
            run()
        }
    }
    var selection = 0
    private(set) var hits: [SearchHit] = []

    @ObservationIgnored private let index: any SearchIndex
    @ObservationIgnored private let notes: any NoteLookup
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let clock: any Clock
    @ObservationIgnored private var task: Task<Void, Never>?

    init(index: any SearchIndex, notes: any NoteLookup, navigator: Navigator, clock: any Clock) {
        self.index = index
        self.notes = notes
        self.navigator = navigator
        self.clock = clock
    }

    var words: [String] {
        SearchQueryParser.parse(query, now: clock.now(), timeZone: clock.timeZone).words
    }

    var recentHits: [SearchHit] {
        let byID = Dictionary(notes.summaries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let ids = navigator.recent + navigator.frequent.filter { navigator.recent.contains($0) == false }
        return ids.compactMap { byID[$0] }.prefix(Self.noteLimit).map { SearchHit(summary: $0, snippet: $0.space?.rawValue ?? "", rank: 0) }
    }

    func open(query initial: String = "") {
        query = initial
        selection = 0
        if initial.isEmpty { hits = [] }
        isOpen = true
    }

    func close() {
        task?.cancel()
        isOpen = false
    }

    func items(commands: [PaletteCommand]) -> [PaletteItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let notes = trimmed.isEmpty ? recentHits : hits
        let matching = commands.filter { Self.matches($0.title, query: trimmed) }.prefix(trimmed.isEmpty ? 6 : Self.commandLimit)
        return notes.map(PaletteItem.note) + matching.map(PaletteItem.command)
    }

    func move(_ offset: Int, count: Int) {
        guard count > 0 else { return }
        selection = (selection + offset + count) % count
    }

    func waitForResults() async {
        await task?.value
    }

    static func matches(_ title: String, query: String) -> Bool {
        let words = query.lowercased().split(separator: " ")
        guard words.isEmpty == false else { return true }
        let lower = title.lowercased()
        return words.allSatisfy { lower.contains($0) }
    }

    private func run() {
        task?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false else {
            hits = []
            return
        }
        let parsed = SearchQueryParser.parse(trimmed, now: clock.now(), timeZone: clock.timeZone)
        let lowered = parsed.words.map { $0.lowercased() }
        if parsed.filters.isEmpty, lowered.isEmpty == false {
            let titleHits = notes.summaries.filter { summary in lowered.allSatisfy { summary.title.lowercased().contains($0) } }
                .map { SearchHit(summary: $0, snippet: $0.preview, rank: 0) }
            hits = Array(SearchMatchPolicy.sorted(titleHits, words: parsed.words).prefix(Self.noteLimit))
        }
        task = Task { [weak self] in
            try? await Task.sleep(for: SearchStore.debounce)
            guard Task.isCancelled == false, let self else { return }
            guard let found = try? await index.search(parsed, limit: Self.noteLimit), Task.isCancelled == false else { return }
            hits = found
        }
    }
}
