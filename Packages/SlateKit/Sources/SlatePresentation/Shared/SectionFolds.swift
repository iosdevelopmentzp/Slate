import Foundation
import SlateDomain

@MainActor
final class SectionFolds {
    private let store: any KeyValueStore
    private var folds: [String: [String]]

    init(store: any KeyValueStore) {
        self.store = store
        folds = store.decode([String: [String]].self, forKey: Keys.folds) ?? [:]
    }

    func sections(for note: NoteID?) -> [String] {
        guard let note else { return [] }
        return folds[note.rawValue] ?? []
    }

    func set(_ sections: [String], for note: NoteID?) {
        guard let note, folds[note.rawValue] ?? [] != sections else { return }
        folds[note.rawValue] = sections.isEmpty ? nil : sections
        store.encode(folds, forKey: Keys.folds)
    }

    private enum Keys {
        static let folds = "editor.collapsedSections"
    }
}
