import Foundation

package struct Snapshot: Identifiable, Hashable, Sendable {
    package let hash: String
    package let date: Date
    package let message: String

    package var id: String {
        hash
    }

    package init(hash: String, date: Date, message: String) {
        self.hash = hash
        self.date = date
        self.message = message
    }
}
