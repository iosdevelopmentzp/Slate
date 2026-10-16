import Testing
@testable import SlateUI

@Suite struct CountTextTests {
    @Test func usesSingularForOne() {
        #expect(CountText.count(1, "note") == "1 note")
    }

    @Test func addsAnSForOtherCounts() {
        #expect(CountText.count(0, "note") == "0 notes")
        #expect(CountText.count(23, "note") == "23 notes")
    }

    @Test func usesTheGivenPlural() {
        #expect(CountText.count(2, "open checkbox", "open checkboxes") == "2 open checkboxes")
    }
}
