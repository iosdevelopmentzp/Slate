import Foundation
import SlateMocks
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct QuickCaptureUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies

    init() {
        (ports, spies) = Ports.spies()
    }

    @Test func twoLinesBecomeANoteInInbox() async throws {
        let document = try #require(try await UseCases(ports: ports).capture.execute(CaptureInput(text: "Engine delegate must be weak\ncheck the other one too")))

        #expect(document.path == VaultPath(rawValue: "Inbox/Engine delegate must be weak.md"))
        #expect(document.body == "check the other one too\n")
    }

    @Test func aTicketAtTheStartMakesATask() async throws {
        let document = try #require(try await UseCases(ports: ports).capture.execute(CaptureInput(text: "ABC-2324 Profile screen leaks memory")))

        #expect(document.path == VaultPath(rawValue: "Tasks/ABC-2324 Profile screen leaks memory.md"))
        #expect(document.header.ticket == "ABC-2324")
        #expect(document.header.branch == "feature/ABC-2324-profile-screen-leaks-memory")
        #expect(document.header.status == "todo")
        #expect(document.body.hasPrefix("## Context"))
    }

    @Test func todayAppendsALogLine() async throws {
        let document = try #require(try await UseCases(ports: ports).capture.execute(CaptureInput(text: "standup at 10", destination: .today)))

        #expect(document.path == VaultPath(rawValue: "Daily/2027-01-15.md"))
        #expect(document.body.contains("- 11:00 standup at 10"))
    }

    @Test func emptyTextSavesNothing() async throws {
        #expect(try await UseCases(ports: ports).capture.execute(CaptureInput(text: "  \n ")) == nil)
        #expect(spies.files.calls.isEmpty)
    }
}
