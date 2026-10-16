import Foundation

package struct NoteID: Hashable, Sendable, Codable {
    package let rawValue: String

    package init(rawValue: String) {
        self.rawValue = rawValue
    }

    package static func generate() -> NoteID {
        NoteID(rawValue: UUID().uuidString.lowercased())
    }

    package static func forPath(_ path: VaultPath) -> NoteID {
        NoteID(rawValue: "path:\(path.rawValue)")
    }

    package var isPathBased: Bool {
        rawValue.hasPrefix("path:")
    }
}
