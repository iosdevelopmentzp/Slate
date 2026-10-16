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

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = HistorySettings()
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? defaults.isEnabled
        intervalMinutes = try container.decodeIfPresent(Int.self, forKey: .intervalMinutes) ?? defaults.intervalMinutes
        remote = try container.decodeIfPresent(String.self, forKey: .remote) ?? defaults.remote
        pushOnQuit = try container.decodeIfPresent(Bool.self, forKey: .pushOnQuit) ?? defaults.pushOnQuit
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
