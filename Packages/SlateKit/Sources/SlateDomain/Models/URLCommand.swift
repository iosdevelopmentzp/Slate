import Foundation

package enum URLCommand: Hashable, Sendable {
    case new(NoteDraft)
    case open(OpenTarget)
    case append(text: String, target: AppendTarget, section: String?)
    case capture
    case search(String)

    package enum OpenTarget: Hashable, Sendable {
        case ticket(String)
        case title(String)
        case id(NoteID)
    }
}
