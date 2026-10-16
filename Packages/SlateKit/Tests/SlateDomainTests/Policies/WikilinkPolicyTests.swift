import Foundation
import Testing
@testable import SlateDomain

@Suite struct WikilinkPolicyTests {
    @Test func targetsSkipCode() {
        let body = "See [[Alpha]] and [[Tasks/Beta|the beta]] and [[Gamma#Plan]].\n`[[Not]]`\n```\n[[Fenced]]\n```"

        #expect(WikilinkPolicy.targets(in: body) == ["Alpha", "Tasks/Beta", "Gamma"])
    }

    @Test func parseSplitsSpaceHeadingAndAlias() {
        #expect(WikilinkPolicy.parse("Tasks/Beta#Plan|b") == WikilinkPolicy.Target(space: "Tasks", stem: "Beta", heading: "Plan"))
    }

    @Test func rewriteKeepsAliasHeadingAndSpace() {
        let body = "[[Old]] [[old|alias]] [[Old#H]] [[Tasks/Old]] [[Older]] `[[Old]]`"

        #expect(WikilinkPolicy.rewrite(body, from: "Old", to: "New") == "[[New]] [[New|alias]] [[New#H]] [[Tasks/New]] [[Older]] `[[Old]]`")
    }

    @Test func rewriteLeavesFencesAlone() {
        let body = "```\n[[Old]]\n```\n[[Old]]"

        #expect(WikilinkPolicy.rewrite(body, from: "Old", to: "New") == "```\n[[Old]]\n```\n[[New]]")
    }

    @Test func resolvePrefersTheSameSpaceThenTheNewest() {
        let notes = [
            NoteSummary(id: NoteID(rawValue: "a"), path: VaultPath(rawValue: "Notes/Plan.md"), title: "Plan", updated: Date(timeIntervalSince1970: 2), preview: ""),
            NoteSummary(id: NoteID(rawValue: "b"), path: VaultPath(rawValue: "Tasks/plan.md"), title: "plan", updated: Date(timeIntervalSince1970: 1), preview: ""),
            NoteSummary(id: NoteID(rawValue: "c"), path: VaultPath(rawValue: "Inbox/Plan.md"), title: "Plan", updated: Date(timeIntervalSince1970: 3), preview: ""),
        ]

        #expect(WikilinkPolicy.resolve("Plan", candidates: notes, from: VaultPath(rawValue: "Tasks/X.md"))?.id == NoteID(rawValue: "b"))
        #expect(WikilinkPolicy.resolve("Plan", candidates: notes, from: VaultPath(rawValue: "Daily/X.md"))?.id == NoteID(rawValue: "c"))
        #expect(WikilinkPolicy.resolve("Notes/Plan", candidates: notes, from: nil)?.id == NoteID(rawValue: "a"))
        #expect(WikilinkPolicy.resolve("Missing", candidates: notes, from: nil) == nil)
    }
}
