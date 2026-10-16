import Testing
@testable import SlateDomain

@Suite struct SpaceNamePolicyTests {
    @Test func sanitisesLikeAStem() {
        #expect(SpaceNamePolicy.validated("  Work/Home ") == SpaceName(rawValue: "Work-Home"))
    }

    @Test func rejectsEmptyAndReservedNames() {
        #expect(SpaceNamePolicy.validated("   ") == nil)
        #expect(SpaceNamePolicy.validated("_attachments") == nil)
    }

    @Test func leadingDotsAreRemoved() {
        #expect(SpaceNamePolicy.validated(".hidden") == SpaceName(rawValue: "hidden"))
    }
}
