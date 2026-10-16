import Foundation
import SlateDomain

package enum AppEvent: Equatable, Sendable {
    case noteCreated(NoteID)
    case noteSaved(NoteID)
    case indexUpdated
}
