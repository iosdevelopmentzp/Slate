import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class Navigator {
    var space: SpaceName? {
        didSet {
            guard space != oldValue else { return }
            store.set(space?.rawValue, forKey: Keys.space)
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
        space = store.string(forKey: Keys.space).map(SpaceName.init(rawValue:))
        selectedNote = store.string(forKey: Keys.selectedNote).map(NoteID.init(rawValue:))
    }

    func show(space: SpaceName?) {
        self.space = space
    }

    func select(_ id: NoteID?) {
        selectedNote = id
    }

    private enum Keys {
        static let space = "navigator.space"
        static let selectedNote = "navigator.selectedNote"
    }
}
