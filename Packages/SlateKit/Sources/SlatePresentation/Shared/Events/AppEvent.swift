import Foundation
import SlateDomain

package enum AppEvent: Equatable, Sendable {
    case indexUpdated
    case spacesChanged
    case vaultChanged(Set<VaultPath>)
    case vaultRescanned
    case noteCreated(NoteID, caret: Int)
    case noteSaved(NoteID)
    case noteMoved(from: VaultPath, to: VaultPath)
    case noteTrashed(VaultPath)
    case searchOpened(NoteID, words: [String])
}
