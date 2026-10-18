import Foundation
import Testing
@testable import SlateDomain

@Suite struct LineDiffPolicyTests {
    @Test func changedLinesShowAsRemovedThenAdded() {
        let lines = LineDiffPolicy.lines(from: "a\nb\nc\n", to: "a\nB\nc\nd\n")

        #expect(lines == [DiffLine(.same, "a"), DiffLine(.removed, "b"), DiffLine(.added, "B"), DiffLine(.same, "c"), DiffLine(.added, "d")])
        #expect(LineDiffPolicy.counts(lines) == (added: 2, removed: 1))
    }

    @Test func emptyTextsAndEqualTexts() {
        #expect(LineDiffPolicy.lines(from: "", to: "x") == [DiffLine(.added, "x")])
        #expect(LineDiffPolicy.lines(from: "x\n", to: "") == [DiffLine(.removed, "x")])
        #expect(LineDiffPolicy.lines(from: "x\ny", to: "x\ny\n").allSatisfy { $0.kind == .same })
    }
}
