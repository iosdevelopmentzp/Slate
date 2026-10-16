import Foundation
import Testing
@testable import SlateDomain

@Suite struct SettingsDecodingTests {
    @Test func olderTrackerSettingsStillDecode() throws {
        let old = #"{"trackerBaseURL":"https://example.atlassian.net","ticketPattern":"x","gitHostBaseURL":"","gitProjectPath":"","ticketLabel":"Ticket","mergeRequestLabel":"MR"}"#

        let settings = try JSONDecoder().decode(TrackerSettings.self, from: Data(old.utf8))

        #expect(settings.trackerBaseURL == "https://example.atlassian.net")
        #expect(settings.trackerEmail.isEmpty)
    }

    @Test func partialHistoryAndDailySettingsUseDefaults() throws {
        #expect(try JSONDecoder().decode(HistorySettings.self, from: Data(#"{"remote":"origin"}"#.utf8)) == HistorySettings(remote: "origin"))
        #expect(try JSONDecoder().decode(DailySettings.self, from: Data(#"{"carriesOver":false}"#.utf8)) == DailySettings(carriesOver: false))
    }
}
