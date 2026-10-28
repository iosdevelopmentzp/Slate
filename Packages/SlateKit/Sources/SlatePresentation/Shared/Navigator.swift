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

    var selectedFile: VaultPath? {
        didSet {
            guard selectedFile != oldValue else { return }
            store.set(selectedFile?.rawValue, forKey: Keys.selectedFile)
        }
    }

    @ObservationIgnored private let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
        source = ListSource(storedValue: store.string(forKey: Keys.source))
        selectedNote = store.string(forKey: Keys.selectedNote).map(NoteID.init(rawValue:))
        selectedFile = store.string(forKey: Keys.selectedFile).map(VaultPath.init(rawValue:))
    }

    var space: SpaceName? {
        source.space
    }

    func show(_ source: ListSource) {
        self.source = source
    }

    func select(_ id: NoteID?) {
        selectedFile = nil
        selectedNote = id
    }

    func select(file path: VaultPath?) {
        selectedFile = path
        guard path != nil else { return }
        selectedNote = nil
    }

    private enum Keys {
        static let source = "navigator.source"
        static let selectedNote = "navigator.selectedNote"
        static let selectedFile = "navigator.selectedFile"
    }
}
