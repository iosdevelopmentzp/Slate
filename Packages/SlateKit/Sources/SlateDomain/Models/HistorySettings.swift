import Foundation

package struct HistorySettings: Hashable, Sendable, Codable {
    package static let key = "history.settings"
    package static let intervals = [5, 10, 30, 60]

    package var isEnabled: Bool
    package var intervalMinutes: Int
    package var remote: String
    package var pushOnQuit: Bool

    package init(isEnabled: Bool = true, intervalMinutes: Int = 10, remote: String = "", pushOnQuit: Bool = true) {
        self.isEnabled = isEnabled
        self.intervalMinutes = intervalMinutes
        self.remote = remote
        self.pushOnQuit = pushOnQuit
    }

    package var hasRemote: Bool {
        remote.trimmingCharacters(in: .whitespaces).isEmpty == false
    }

    package static func load(from store: any KeyValueStore) -> HistorySettings {
        store.decode(HistorySettings.self, forKey: key) ?? HistorySettings()
    }

    package func save(to store: any KeyValueStore) {
        store.encode(self, forKey: Self.key)
    }
}
