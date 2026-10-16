import Foundation

package enum EditorLink: Equatable, Sendable {
    case url(String)
    case wiki(String)
    case pattern(id: String, match: String)
}
