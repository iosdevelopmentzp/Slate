import Foundation
import Testing
@testable import SlateEditor

@Suite struct WikiQueryTests {

    @Test func anOpenLinkGivesItsStartAndQuery() {
        #expect(WikiQuery.open(before: "see [[Trip pl") == WikiQuery.Open(start: 4, query: "Trip pl"))
        #expect(WikiQuery.open(before: "see [[") == WikiQuery.Open(start: 4, query: ""))
    }

    @Test func aClosedOrBrokenLinkIsNotOpen() {
        #expect(WikiQuery.open(before: "see [[Trip]] now") == nil)
        #expect(WikiQuery.open(before: "see [x] now") == nil)
    }

    @Test func aClosedLinkGivesItsTargetAndLabel() {
        #expect(WikiQuery.closed(before: "see [[Trip Plan]]") == WikiQuery.Closed(range: NSRange(location: 4, length: 13), target: "Trip Plan", label: "Trip Plan"))
        #expect(WikiQuery.closed(before: "[[Trip|the trip]]")?.label == "the trip")
        #expect(WikiQuery.closed(before: "see [[]]") == nil)
        #expect(WikiQuery.closed(before: "see [Trip]]") == nil)
    }
}
