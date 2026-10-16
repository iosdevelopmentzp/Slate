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
        }
    }

    @ObservationIgnored private let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
        source = ListSource(storedValue: store.string(forKey: Keys.source))
        selectedNote = store.string(forKey: Keys.selectedNote).map(NoteID.init(rawValue:))
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
    }
}
