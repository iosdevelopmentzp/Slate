import Foundation

package struct UpdateCommit: Hashable, Sendable {
    package let hash: String
    package let subject: String

    package init(hash: String, subject: String) {
        self.hash = hash
        self.subject = subject
    }
}
