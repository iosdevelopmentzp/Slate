import Foundation
import Testing
@testable import SlateDomain

@Suite struct DailyPolicyTests {
    private let zone = TimeZone(secondsFromGMT: 3 * 3_600)!
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func stemIsTheLocalDate() {
        #expect(DailyPolicy.stem(for: now, timeZone: zone) == "2027-01-15")
        #expect(DailyPolicy.isDailyStem("2027-01-15"))
        #expect(DailyPolicy.isDailyStem("Notes") == false)
    }

    @Test func dayMovesAcrossMonths() {
        #expect(DailyPolicy.day(-1, from: "2027-03-01", timeZone: zone) == "2027-02-28")
        #expect(DailyPolicy.day(1, from: "2027-12-31", timeZone: zone) == "2028-01-01")
    }

    @Test func logLineHasTheTimeAndIndentsMoreLines() {
        #expect(DailyPolicy.logLine("Fixed it", at: now, timeZone: zone) == "- 11:00 Fixed it")
        #expect(DailyPolicy.logLine("one\ntwo", at: now, timeZone: zone) == "- 11:00 one\n  two")
    }

    @Test func carryOverTakesOpenItemsOutsideCode() {
        let body = "## Log\n- [ ] open one\n- [x] done\n```\n- [ ] in code\n```\n  - [ ] nested"

        #expect(DailyPolicy.carryOver(from: body) == ["- [ ] open one", "- [ ] nested"])
    }

    @Test func previousStemIsTheLatestEarlierDay() {
        #expect(DailyPolicy.previousStem(before: "2027-01-15", among: ["2027-01-10", "2027-01-14", "2027-01-15", "2027-01-20", "Other"]) == "2027-01-14")
        #expect(DailyPolicy.previousStem(before: "2027-01-15", among: []) == nil)
    }
}
