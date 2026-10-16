import Foundation

package struct TrackerSettings: Hashable, Sendable, Codable {
    package static let defaultTicketPattern = #"\b([A-Z][A-Z0-9]+-\d+)\b"#
    package static let key = "tracker.settings"

    package var trackerBaseURL: String
    package var ticketPattern: String
    package var gitHostBaseURL: String
    package var gitProjectPath: String
    package var ticketLabel: String
    package var mergeRequestLabel: String

    package init(
        trackerBaseURL: String = "",
        ticketPattern: String = TrackerSettings.defaultTicketPattern,
        gitHostBaseURL: String = "",
        gitProjectPath: String = "",
        ticketLabel: String = "Ticket",
        mergeRequestLabel: String = "MR"
    ) {
        self.trackerBaseURL = trackerBaseURL
        self.ticketPattern = ticketPattern
        self.gitHostBaseURL = gitHostBaseURL
        self.gitProjectPath = gitProjectPath
        self.ticketLabel = ticketLabel
        self.mergeRequestLabel = mergeRequestLabel
    }

    package static func load(from store: any KeyValueStore) -> TrackerSettings {
        store.decode(TrackerSettings.self, forKey: key) ?? TrackerSettings()
    }

    package func save(to store: any KeyValueStore) {
        store.encode(self, forKey: Self.key)
    }
}
