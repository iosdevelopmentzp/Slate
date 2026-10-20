import Foundation
import Testing
@testable import SlateDomain

@Suite struct ExportMarkdownPolicyTests {
    @Test func wikilinksBecomeTheirText() {
        #expect(ExportMarkdownPolicy.prepared("See [[Plan]] and [[Notes/Log#Today|the log]].") == "See Plan and the log.")
    }

    @Test func equalSignsBecomeMarks() {
        #expect(ExportMarkdownPolicy.prepared("A ==key point== and a == b.") == "A <mark>key point</mark> and a == b.")
    }

    @Test func codeStaysAsItIs() {
        let body = "Use `[[x]]` and `==y==`.\n\n```\n[[Plan]] ==z==\n```"

        #expect(ExportMarkdownPolicy.prepared(body) == body)
    }
}
