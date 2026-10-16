import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class Navigator {
    var source: ListSource {
        didSet {
            guard source != oldValue else { return }
            store.set(source.storedValue, forKey: Keys.source)
        }
    }

    var selectedNote: NoteID? {
        didSet {
            guard selectedNote != oldValue else { return }
            store.set(selectedNote?.rawValue, forKey: Keys.selectedNote)
            if let selectedNote {
                remember(selectedNote)
            }
        }
    }
    private(set) var recent: [NoteID] = []
    private(set) var openCounts: [String: String] = [:]

    @ObservationIgnored private let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
        source = ListSource(storedValue: store.string(forKey: Keys.source))
        recent = (store.strings(forKey: Keys.recent) ?? []).map(NoteID.init(rawValue:))
        openCounts = store.stringMap(forKey: Keys.counts) ?? [:]
        selectedNote = store.string(forKey: Keys.selectedNote).map(NoteID.init(rawValue:))
    }

    static let recentLimit = 20

    var frequent: [NoteID] {
        openCounts
            .compactMap { key, value in Int(value).map { (NoteID(rawValue: key), $0) } }
            .filter { $0.1 > 2 }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map(\.0)
    }

    private func remember(_ id: NoteID) {
        recent.removeAll { $0 == id }
        recent.insert(id, at: 0)
        if recent.count > Self.recentLimit {
            recent.removeLast(recent.count - Self.recentLimit)
        }
        store.set(recent.map(\.rawValue), forKey: Keys.recent)
        let count = (Int(openCounts[id.rawValue] ?? "0") ?? 0) + 1
        openCounts[id.rawValue] = String(count)
        if openCounts.count > 200 {
            let keep = Set(recent.map(\.rawValue))
            openCounts = openCounts.filter { keep.contains($0.key) || (Int($0.value) ?? 0) > 2 }
        }
        store.set(openCounts, forKey: Keys.counts)
    }

    var space: SpaceName? {
        source.space
    }

    func show(_ source: ListSource) {
        self.source = source
    }

    func select(_ id: NoteID?) {
        selectedNote = id
    }

    private enum Keys {
        static let source = "navigator.source"
        static let selectedNote = "navigator.selectedNote"
        static let recent = "navigator.recent"
        static let counts = "navigator.openCounts"
    }
}
