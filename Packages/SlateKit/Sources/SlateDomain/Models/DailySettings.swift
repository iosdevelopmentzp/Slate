import Foundation

package struct DailySettings: Hashable, Sendable, Codable {
    package static let key = "daily.settings"

    package var isEnabled: Bool
    package var carriesOver: Bool
    package var template: String

    package init(isEnabled: Bool = true, carriesOver: Bool = true, template: String = NoteType.daily.name) {
        self.isEnabled = isEnabled
        self.carriesOver = carriesOver
        self.template = template
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = DailySettings()
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? defaults.isEnabled
        carriesOver = try container.decodeIfPresent(Bool.self, forKey: .carriesOver) ?? defaults.carriesOver
        template = try container.decodeIfPresent(String.self, forKey: .template) ?? defaults.template
    }

    package static func load(from store: any KeyValueStore) -> DailySettings {
        store.decode(DailySettings.self, forKey: key) ?? DailySettings()
    }

    package func save(to store: any KeyValueStore) {
        store.encode(self, forKey: Self.key)
    }
}
