import Foundation
import SlateDomain

struct NavigationPlace: Hashable {
    let source: ListSource
    let note: NoteID?
    let file: VaultPath?

    var isEmpty: Bool {
        note == nil && file == nil
    }

    func isSameTarget(as other: NavigationPlace) -> Bool {
        file != nil ? file == other.file : note == other.note && other.file == nil
    }
}
