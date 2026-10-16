import Foundation

package enum JournalPolicy {
    package static func shouldOffer(_ entry: JournalEntry?, for document: NoteDocument) -> Bool {
        guard let entry, entry.text != document.body else { return false }
        return entry.savedAt > document.meta.modified
    }
}
