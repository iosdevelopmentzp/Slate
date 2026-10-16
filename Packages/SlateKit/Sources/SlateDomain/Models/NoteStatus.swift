import Foundation

package enum NoteStatus: String, Hashable, Sendable, Codable, CaseIterable {
    case todo
    case active
    case review
    case done
    case dropped
}
