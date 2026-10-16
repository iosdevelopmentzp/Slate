import Foundation
import Testing
@testable import SlateDomain

@Suite struct ConflictCopyPolicyTests {
    @Test func titleCarriesTheLocalDateAndTime() {
        let title = ConflictCopyPolicy.title(for: "Plan", at: Date(timeIntervalSince1970: 1_800_000_000), timeZone: TimeZone(secondsFromGMT: 3 * 3_600)!)

        #expect(title == "Plan (conflict 2027-01-15 1100)")
    }
}
