import SlateDomain
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct AppEventsTests {
    @Test func subscribersReceivePostedEvents() {
        let events = AppEvents()
        var received: [AppEvent] = []
        let token = events.subscribe { received.append($0) }

        events.post(.indexUpdated)

        #expect(received == [.indexUpdated])
        _ = token
    }

    @Test func releasedTokenStopsDelivery() {
        let events = AppEvents()
        var received: [AppEvent] = []
        var token: SubscriptionToken? = events.subscribe { received.append($0) }
        _ = token

        token = nil
        events.post(.indexUpdated)

        #expect(received.isEmpty)
    }
}
