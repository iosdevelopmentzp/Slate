import Foundation

package enum EditorLink: Equatable, Sendable {
    case url(String)
    case wiki(String)
    case reference(TextReference)
}
