import Foundation

package struct Snapshot: Identifiable, Hashable, Sendable {
    package let hash: String
    package let date: Date
    package let message: String

    package static let versionPrefix = "version: "
    package static let agentPrefix = "agent: "

    package var id: String {
        hash
    }

    package var versionName: String? {
        guard message.hasPrefix(Self.versionPrefix) else { return nil }
        let name = message.dropFirst(Self.versionPrefix.count).trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }

    package var isByAgent: Bool {
        message.hasPrefix(Self.agentPrefix)
    }

    package init(hash: String, date: Date, message: String) {
        self.hash = hash
        self.date = date
        self.message = message
    }
}
