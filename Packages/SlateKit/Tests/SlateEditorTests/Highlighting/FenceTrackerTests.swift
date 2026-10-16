import Foundation
import Testing
@testable import SlateEditor

@Suite struct FenceTrackerTests {
    @Test func linesInsideAFenceAreCode() {
        let tracker = FenceTracker(text: "a\n```swift\nlet x = 1\n```\nb" as NSString)

        #expect(tracker.lines.map(\.kind) == [.paragraph, .fenceOpen(language: "swift"), .code(language: "swift"), .fenceClose, .paragraph])
    }

    @Test func unclosedFenceRunsToTheEnd() {
        let tracker = FenceTracker(text: "```\nx\n# y" as NSString)

        #expect(tracker.lines.map(\.kind) == [.fenceOpen(language: ""), .code(language: ""), .code(language: "")])
    }

    @Test func longerFenceIsNotClosedByAShorterOne() {
        let tracker = FenceTracker(text: "````\n```\nx\n````" as NSString)

        #expect(tracker.lines.map(\.kind) == [.fenceOpen(language: ""), .code(language: ""), .code(language: ""), .fenceClose])
    }

    @Test func tildeFenceIsNotClosedByBackticks() {
        let tracker = FenceTracker(text: "~~~\n```\n~~~" as NSString)

        #expect(tracker.lines.map(\.kind) == [.fenceOpen(language: ""), .code(language: ""), .fenceClose])
    }

    @Test func openingAFenceAboveTurnsTheLinesBelowIntoCode() {
        let before = "a\n# b\n- c" as NSString
        let tracker = FenceTracker(text: before)
        let after = "```\na\n# b\n- c" as NSString

        let changed = tracker.update(text: after, editedRange: NSRange(location: 0, length: 4), changeInLength: 4)

        #expect(tracker.lines.map(\.kind) == [.fenceOpen(language: ""), .code(language: ""), .code(language: ""), .code(language: "")])
        #expect(changed == NSRange(location: 0, length: after.length))
    }

    @Test func editInsideAParagraphStopsAtTheEditedLine() {
        let before = "a\nb\nc\nd" as NSString
        let tracker = FenceTracker(text: before)
        let after = "a\nbx\nc\nd" as NSString

        let changed = tracker.update(text: after, editedRange: NSRange(location: 3, length: 1), changeInLength: 1)

        #expect(changed == NSRange(location: 2, length: 2))
        #expect(tracker.lines.map(\.start) == [0, 2, 5, 7])
    }

    @Test func removingAFenceRestoresTheLinesBelow() {
        let tracker = FenceTracker(text: "```\n# a\nb" as NSString)
        let after = "``\n# a\nb" as NSString

        tracker.update(text: after, editedRange: NSRange(location: 2, length: 0), changeInLength: -1)

        #expect(tracker.lines.map(\.kind) == [.paragraph, .heading(level: 1, markLength: 2), .paragraph])
    }

    @Test func joiningTwoLinesMergesTheirState() {
        let tracker = FenceTracker(text: "a\nb\nc" as NSString)
        let after = "ab\nc" as NSString

        tracker.update(text: after, editedRange: NSRange(location: 1, length: 0), changeInLength: -1)

        #expect(tracker.lines.map(\.start) == [0, 3])
        #expect(tracker.lines.map(\.length) == [2, 1])
    }

    @Test func splittingALineAddsOne() {
        let tracker = FenceTracker(text: "ab" as NSString)
        let after = "a\nb" as NSString

        tracker.update(text: after, editedRange: NSRange(location: 1, length: 1), changeInLength: 1)

        #expect(tracker.lines.map(\.start) == [0, 2])
    }

    @Test func emptyTextHasOneBlankLine() {
        let tracker = FenceTracker(text: "" as NSString)

        #expect(tracker.lines.map(\.kind) == [.blank])
    }

    @Test func incrementalUpdatesMatchAFullScan() {
        var text = "# Title\n\n```swift\nlet a = 1\n```\n- [ ] item\n" as String
        let tracker = FenceTracker(text: text as NSString)
        let edits: [(Int, Int, String)] = [(9, 0, "x"), (0, 2, ""), (10, 0, "```\n"), (3, 5, "\n\n"), (0, 0, "~~~\n")]
        for (location, length, replacement) in edits {
            let ns = text as NSString
            let safeLocation = min(location, ns.length)
            let safeLength = min(length, ns.length - safeLocation)
            text = ns.replacingCharacters(in: NSRange(location: safeLocation, length: safeLength), with: replacement)
            tracker.update(text: text as NSString, editedRange: NSRange(location: safeLocation, length: (replacement as NSString).length), changeInLength: (replacement as NSString).length - safeLength)
            #expect(tracker.lines == FenceTracker(text: text as NSString).lines)
        }
    }
}
