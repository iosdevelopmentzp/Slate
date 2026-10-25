import MCP
import SlateDomain
import Testing
@testable import SlateCLI

@Suite struct MCPArgumentCheckTests {
    private let check = MCPArgumentCheck(
        Tool(
            name: "make",
            description: "Make a thing.",
            inputSchema: [
                "type": "object",
                "properties": ["title": ["type": "string"], "limit": ["type": "integer"], "done": ["type": "boolean"]],
                "required": ["title"],
            ]
        )
    )

    @Test func acceptsKnownArgumentsOfTheRightType() throws {
        try check.check(["title": "A", "limit": 3, "done": true])
        try check.check(["title": "A", "limit": "3", "done": "false"])
    }

    @Test func listsTheRequiredArgumentsFirst() {
        #expect(check.accepted == ["title", "done", "limit"])
    }

    @Test func reportsEveryProblemInOneError() {
        #expect(throws: AgentError.badArguments("make", unknown: ["body", "text"], missing: ["title"], wrongType: ["limit (a number)"], accepted: ["title", "done", "limit"], required: ["title"])) {
            try check.check(["text": "A", "body": "B", "limit": "many"])
        }
    }

    @Test func treatsANullAsAMissingArgument() {
        #expect(throws: AgentError.badArguments("make", unknown: [], missing: ["title"], wrongType: [], accepted: ["title", "done", "limit"], required: ["title"])) {
            try check.check(["title": .null, "extra": .null])
        }
    }

    @Test func skipsTheRequiredArgumentsWhenAsked() throws {
        try check.check(["limit": 1], requireAll: false)
    }

    @Test func allowsTheExtraNames() throws {
        try MCPArgumentCheck(named: "append_to_note", alsoAllowed: ["tool", "task"])?.check(["tool": "append_to_note", "task": "ABC-1", "text": "x"], requireAll: false)
    }

    @Test func knowsOnlyTheToolsOfTheCatalog() {
        #expect(MCPArgumentCheck(named: "delete_everything") == nil)
    }
}
