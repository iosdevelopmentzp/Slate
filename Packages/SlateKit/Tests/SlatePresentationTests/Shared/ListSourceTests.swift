import SlateDomain
import Testing
@testable import SlatePresentation

@Suite struct ListSourceTests {
    @Test func storedValueRoundTrips() {
        for source in [ListSource.all, .trash, .space(SpaceName(rawValue: "My Notes"))] {
            #expect(ListSource(storedValue: source.storedValue) == source)
        }
    }

    @Test func unknownValueMeansAll() {
        #expect(ListSource(storedValue: nil) == .all)
        #expect(ListSource(storedValue: "weird") == .all)
    }
}
