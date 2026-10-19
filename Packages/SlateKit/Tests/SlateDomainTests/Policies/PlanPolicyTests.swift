import Foundation
import Testing
@testable import SlateDomain

@Suite struct PlanPolicyTests {
    private let body = "## Context\n\n- [ ] not a step\n\n## Plan\n\n- [x] 1. Read the code\n- [ ] 2. Write the fix\n  - [ ] 3. Add a test\n- [ ] \n\n## Log\n"

    @Test func itemsAreTheChecklistLinesOfThePlan() {
        #expect(PlanPolicy.items(in: body) == [
            PlanItem(number: 1, text: "1. Read the code", isDone: true),
            PlanItem(number: 2, text: "2. Write the fix", isDone: false),
            PlanItem(number: 3, text: "3. Add a test", isDone: false),
        ])
        #expect(PlanPolicy.items(in: "## Context\n\n- [ ] a\n").isEmpty)
    }

    @Test func settingByNumberOrTextChangesOneLine() throws {
        let byNumber = try PlanPolicy.setting("2", done: true, in: body)
        let byText = try PlanPolicy.setting("add a TEST", done: true, in: body)
        let reopened = try PlanPolicy.setting("1", done: false, in: body)

        #expect(byNumber == body.replacingOccurrences(of: "- [ ] 2. Write", with: "- [x] 2. Write"))
        #expect(byText == body.replacingOccurrences(of: "  - [ ] 3.", with: "  - [x] 3."))
        #expect(reopened == body.replacingOccurrences(of: "- [x] 1.", with: "- [ ] 1."))
    }

    @Test func theLabelAddsTheNumberOnlyWhenTheTextHasNone() {
        #expect(PlanItem(number: 2, text: "2. Fix", isDone: false).label == "2. Fix")
        #expect(PlanItem(number: 2, text: "Fix", isDone: false).label == "2. Fix")
    }

    @Test func aMissingOrAmbiguousStepIsRefused() {
        #expect(throws: AgentError.noPlanItem("9", steps: ["1. Read the code", "2. Write the fix", "3. Add a test"])) {
            try PlanPolicy.setting("9", done: true, in: body)
        }
        #expect(throws: AgentError.planItemNotUnique("the", count: 2)) { try PlanPolicy.setting("the", done: true, in: body) }
        #expect(throws: AgentError.noPlanItem("x", steps: [])) { try PlanPolicy.setting("x", done: true, in: "## Plan\n\n- [ ] \n") }
    }
}
