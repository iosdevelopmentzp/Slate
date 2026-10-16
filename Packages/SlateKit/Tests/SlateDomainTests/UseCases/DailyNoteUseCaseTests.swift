import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct DailyNoteUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies

    init() {
        (ports, spies) = Ports.spies()
    }

    @Test func todayIsMadeFromTheTemplateWithCarriedItems() async throws {
        spies.files.seed(VaultPath(rawValue: "Daily/2027-01-13.md"), NoteText.make(title: "2027-01-13", body: "- [ ] old"))
        spies.files.seed(VaultPath(rawValue: "Daily/2027-01-14.md"), NoteText.make(title: "2027-01-14", body: "## Log\n- [ ] still open\n- [x] done"))

        let today = try await UseCases(ports: ports).ensureDaily.execute()

        #expect(today.wasCreated)
        #expect(today.document.path == VaultPath(rawValue: "Daily/2027-01-15.md"))
        #expect(today.document.header.type == "daily")
        #expect(today.document.body.hasPrefix("## Carried over\n\n- [ ] still open\n\n## Log\n\n"))
    }

    @Test func anExistingTodayIsOpenedAsIs() async throws {
        spies.files.seed(VaultPath(rawValue: "Daily/2027-01-15.md"), NoteText.make(title: "2027-01-15", body: "mine"))

        let today = try await UseCases(ports: ports).ensureDaily.execute()

        #expect(today.wasCreated == false)
        #expect(today.document.body == "mine")
    }

    @Test func nothingToCarryAddsNoSection() async throws {
        let today = try await UseCases(ports: ports).ensureDaily.execute()

        #expect(today.document.body.hasPrefix("## Log"))
    }

    @Test func appendToTodayAddsATimedLogLine() async throws {
        let document = try await UseCases(ports: ports).append.execute("Fixed the cycle", to: .today, section: nil)

        #expect(document.body.contains("## Log\n\n- 11:00 Fixed the cycle\n\n## Notes"))
    }

    @Test func appendToAnUnknownTicketMakesATask() async throws {
        let document = try await UseCases(ports: ports).append.execute("found", to: .ticket("ABC-9"), section: "Findings")

        #expect(document.path == VaultPath(rawValue: "Tasks/ABC-9.md"))
        #expect(document.header.ticket == "ABC-9")
        #expect(document.body.contains("## Findings\nfound\n") || document.body.contains("## Findings\n\nfound\n"))
    }
}
