import Foundation
import Testing
@testable import SlateEditor

@Suite struct FenceCompletionTests {
    @Test func closingFenceMatchesTheOpening() {
        #expect(FenceCompletion.closingFence(afterLine: "````swift", isUnclosed: true) == "````")
        #expect(FenceCompletion.closingFence(afterLine: "```", isUnclosed: false) == nil)
        #expect(FenceCompletion.closingFence(afterLine: "text", isUnclosed: true) == nil)
    }

    @Test func backtickPairsAtWordBoundaries() {
        #expect(FenceCompletion.backtick(in: "a " as NSString, selection: NSRange(location: 2, length: 0)) == TextEdit(range: NSRange(location: 2, length: 0), replacement: "``", selection: NSRange(location: 3, length: 0)))
        #expect(FenceCompletion.backtick(in: "ab" as NSString, selection: NSRange(location: 1, length: 0)) == nil)
    }

    @Test func backtickStepsOverAClosingOne() {
        #expect(FenceCompletion.backtick(in: "`x`" as NSString, selection: NSRange(location: 2, length: 0)) == TextEdit(range: NSRange(location: 2, length: 0), replacement: "", selection: NSRange(location: 3, length: 0)))
    }

    @Test func backtickWrapsASelection() {
        #expect(FenceCompletion.backtick(in: "a code b" as NSString, selection: NSRange(location: 2, length: 4))?.replacement == "`code`")
    }
}
