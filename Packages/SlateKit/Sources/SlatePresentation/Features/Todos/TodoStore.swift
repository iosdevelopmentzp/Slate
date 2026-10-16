import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class TodoStore {
    var groupsByTicket = false {
        didSet { store.set(groupsByTicket, forKey: Keys.byTicket) }
    }
    private(set) var items: [TodoItem] = []
    private(set) var isLoading = false

    @ObservationIgnored private let index: any SearchIndex
    @ObservationIgnored private let toggleTodo: ToggleTodoUseCase
    @ObservationIgnored private let notes: any NoteLookup
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(index: any SearchIndex, toggleTodo: ToggleTodoUseCase, notes: any NoteLookup, navigator: Navigator, store: any KeyValueStore, activity: ActivityLog, events: AppEvents) {
        self.index = index
        self.toggleTodo = toggleTodo
        self.notes = notes
        self.navigator = navigator
        self.store = store
        self.activity = activity
        self.events = events
        groupsByTicket = store.bool(forKey: Keys.byTicket)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .indexUpdated, .noteSaved:
                guard navigator.source == .todos else { return }
                Task { await self.refresh() }
            default:
                break
            }
        }
    }

    var groups: [TodoGroup] {
        let summaries = Dictionary(notes.summaries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        if groupsByTicket {
            let grouped = Dictionary(grouping: items) { summaries[$0.noteID]?.ticket ?? "" }
            return grouped.keys.sorted { lhs, rhs in lhs.isEmpty == rhs.isEmpty ? lhs < rhs : rhs.isEmpty }.map { ticket in
                TodoGroup(id: "ticket:\(ticket)", title: ticket.isEmpty ? "No ticket" : ticket, detail: nil, noteID: nil, items: grouped[ticket] ?? [])
            }
        }
        let grouped = Dictionary(grouping: items, by: \.noteID)
        return grouped.keys
            .sorted { (summaries[$0]?.updated ?? .distantPast) > (summaries[$1]?.updated ?? .distantPast) }
            .map { id in
                let summary = summaries[id]
                return TodoGroup(id: id.rawValue, title: summary?.title ?? id.rawValue, detail: summary?.space?.rawValue, noteID: id, items: grouped[id] ?? [])
            }
    }

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            defer { isLoading = false }
            let loaded = try await index.todos(isDone: false)
            if loaded != items { items = loaded }
        }
    }

    func toggle(_ item: TodoItem) async {
        do {
            guard let document = try await toggleTodo.execute(item) else {
                activity.log("The checkbox changed in the file", detail: item.text, outcome: .info)
                await refresh()
                return
            }
            items.removeAll { $0 == item }
            events.post(.vaultChanged([document.path]))
            events.post(.noteSaved(document.id))
        } catch {
            activity.log("Cannot check the item", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func open(_ item: TodoItem) {
        navigator.select(item.noteID)
    }

    private enum Keys {
        static let byTicket = "todos.byTicket"
    }
}
