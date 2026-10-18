import Foundation
import Testing
@testable import SlateDomain

@Suite struct TaskLogPolicyTests {
    @Test func entryStartsWithTheLocalDateAndTimeAndIndentsMoreLines() throws {
        let zone = try #require(TimeZone(identifier: "Europe/Kyiv"))
        let date = Date(timeIntervalSince1970: 1_800_000_000)

        let entry = TaskLogPolicy.entry("Found the leak.\nNext: fix it.\n", at: date, timeZone: zone)

        #expect(entry == "- **2027-01-15 10:00** Found the leak.\n  Next: fix it.")
    }

    @Test func aTaskMatchesItsBranchOrABranchWithItsTicket() {
        let task = ProjectTask(id: NoteID(rawValue: "a"), path: VaultPath(rawValue: "MyApp/ABC-1 Fix/ABC-1 Fix.md"), title: "ABC-1 Fix", status: .active, ticket: "ABC-1", branch: "feature/ABC-1-fix", updated: .now)

        #expect(task.matches(branch: "feature/ABC-1-fix"))
        #expect(task.matches(branch: "bugfix/abc-1-other"))
        #expect(task.matches(branch: "feature/ABC-2") == false)
        #expect(task.matches(branch: nil) == false)
    }
}
