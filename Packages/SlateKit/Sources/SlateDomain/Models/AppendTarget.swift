import Foundation

package enum AppendTarget: Hashable, Sendable {
    case today
    case path(VaultPath)
    case id(NoteID)
    case ticket(String)
}
