import Foundation

package enum NoteLinkPolicy {
    package static func openLink(for id: NoteID) -> URL? {
        var components = URLComponents()
        components.scheme = URLCommandParser.scheme
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "id", value: id.rawValue)]
        return components.url
    }
}
