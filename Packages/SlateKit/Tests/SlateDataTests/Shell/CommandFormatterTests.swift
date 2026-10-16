import Testing
@testable import SlateData

@Suite struct CommandFormatterTests {
    @Test func plainArgumentsStayUnquoted() {
        #expect(CommandFormatter.displayCommand("git", ["status", "--short"]) == "git status --short")
    }

    @Test func argumentsWithSpacesAreQuoted() {
        #expect(CommandFormatter.displayCommand("git", ["commit", "-m", "Save notes"]) == "git commit -m 'Save notes'")
    }

    @Test func singleQuotesAreEscaped() {
        #expect(CommandFormatter.displayCommand("echo", ["it's"]) == "echo 'it'\\''s'")
    }

    @Test func multilineScriptsAreHidden() {
        #expect(CommandFormatter.displayCommand("sh", ["-c", "echo a\necho b"]) == "sh -c '…script…'")
    }
}
