import Foundation
import SlateDomain

enum NoteDragPayload {
    static let prefix = "slate-note:"

    static func text(for id: NoteID) -> String {
        prefix + id.rawValue
    }

    static func noteID(from text: String) -> NoteID? {
        guard text.hasPrefix(prefix) else { return nil }
        let raw = String(text.dropFirst(prefix.count))
        return raw.isEmpty ? nil : NoteID(rawValue: raw)
    }
}
