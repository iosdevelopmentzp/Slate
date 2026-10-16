import SlateDomain
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct ActivityLogTests {
    @Test func failedCommandIsLoggedWithItsMessage() {
        let log = ActivityLog()

        log.handle(CommandRecord(command: "git push", cwd: nil, exitCode: 1, error: nil, outputTail: ["rejected"]))

        #expect(log.events.map(\.title) == ["git push"])
        #expect(log.events.first?.detail == "rejected")
        #expect(log.events.first?.outcome == .failure)
    }

    @Test func successfulCommandIsNotLogged() {
        let log = ActivityLog()

        log.handle(CommandRecord(command: "git status", cwd: nil, exitCode: 0, error: nil, outputTail: []))

        #expect(log.events.isEmpty)
    }

    @Test func newestEventComesFirstAndTheListIsCapped() {
        let log = ActivityLog()

        for index in 0..<(ActivityLog.limit + 5) {
            log.log("Event \(index)", detail: "", outcome: .info)
        }

        #expect(log.events.count == ActivityLog.limit)
        #expect(log.events.first?.title == "Event \(ActivityLog.limit + 4)")
    }
}
