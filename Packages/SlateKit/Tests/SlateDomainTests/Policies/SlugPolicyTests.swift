import Foundation
import Testing
@testable import SlateDomain

@Suite struct SlugPolicyTests {
    @Test func slugIsLowercaseWithDashes() {
        #expect(SlugPolicy.slug("Profile screen leaks memory!") == "profile-screen-leaks-memory")
        #expect(SlugPolicy.slug("  Café — déjà vu  ") == "cafe-deja-vu")
    }

    @Test func slugIsCutTo48Characters() {
        let slug = SlugPolicy.slug(String(repeating: "word ", count: 20))

        #expect(slug.count <= 48)
        #expect(slug.hasSuffix("-") == false)
    }

    @Test func branchFollowsThePattern() {
        #expect(SlugPolicy.renderBranch(pattern: "feature/{{ticket}}-{{slug}}", ticket: "ABC-2324", title: "Profile screen leaks memory") == "feature/ABC-2324-profile-screen-leaks-memory")
        #expect(SlugPolicy.renderBranch(pattern: "feature/{{ticket}}-{{slug}}", ticket: "ABC-1", title: "") == "feature/ABC-1")
        #expect(SlugPolicy.renderBranch(pattern: "feature/{{ticket}}-{{slug}}", ticket: nil, title: "x") == nil)
        #expect(SlugPolicy.renderBranch(pattern: nil, ticket: "ABC-1", title: "x") == nil)
    }
}
