import Foundation

package struct TrackerSettings: Hashable, Sendable, Codable {
    package static let defaultTicketPattern = #"\b([A-Z][A-Z0-9]+-\d+)\b"#
    package static let key = "tracker.settings"
    package static let tokenKey = "tracker.token"

    package var trackerBaseURL: String
    package var ticketPattern: String
    package var gitHostBaseURL: String
    package var gitProjectPath: String
    package var ticketLabel: String
    package var mergeRequestLabel: String
    package var trackerEmail: String

    package init(
        trackerBaseURL: String = "",
        ticketPattern: String = TrackerSettings.defaultTicketPattern,
        gitHostBaseURL: String = "",
        gitProjectPath: String = "",
        ticketLabel: String = "Ticket",
        mergeRequestLabel: String = "MR",
        trackerEmail: String = ""
    ) {
        self.trackerBaseURL = trackerBaseURL
        self.ticketPattern = ticketPattern
        self.gitHostBaseURL = gitHostBaseURL
        self.gitProjectPath = gitProjectPath
        self.ticketLabel = ticketLabel
        self.mergeRequestLabel = mergeRequestLabel
        self.trackerEmail = trackerEmail
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = TrackerSettings()
        trackerBaseURL = try container.decodeIfPresent(String.self, forKey: .trackerBaseURL) ?? defaults.trackerBaseURL
        ticketPattern = try container.decodeIfPresent(String.self, forKey: .ticketPattern) ?? defaults.ticketPattern
        gitHostBaseURL = try container.decodeIfPresent(String.self, forKey: .gitHostBaseURL) ?? defaults.gitHostBaseURL
        gitProjectPath = try container.decodeIfPresent(String.self, forKey: .gitProjectPath) ?? defaults.gitProjectPath
        ticketLabel = try container.decodeIfPresent(String.self, forKey: .ticketLabel) ?? defaults.ticketLabel
        mergeRequestLabel = try container.decodeIfPresent(String.self, forKey: .mergeRequestLabel) ?? defaults.mergeRequestLabel
        trackerEmail = try container.decodeIfPresent(String.self, forKey: .trackerEmail) ?? defaults.trackerEmail
    }

    package static func load(from store: any KeyValueStore) -> TrackerSettings {
        store.decode(TrackerSettings.self, forKey: key) ?? TrackerSettings()
    }

    package func save(to store: any KeyValueStore) {
        store.encode(self, forKey: Self.key)
    }
}
