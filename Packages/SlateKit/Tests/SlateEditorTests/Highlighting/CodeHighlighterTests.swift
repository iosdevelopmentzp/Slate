import Foundation
import Testing
@testable import SlateEditor

@Suite struct CodeHighlighterTests {
    private func kinds(_ line: String, _ language: String) -> [String: CodeTokenKind] {
        let ns = line as NSString
        var result: [String: CodeTokenKind] = [:]
        for token in CodeHighlighter.tokens(in: line, language: CodeHighlighter.language(named: language)) {
            result[ns.substring(with: token.range)] = token.kind
        }
        return result
    }

    @Test func swift() {
        let result = kinds("let name: String = \"a // b\" // note", "swift")

        #expect(result["let"] == .keyword)
        #expect(result["String"] == .type)
        #expect(result["\"a // b\""] == .string)
        #expect(result["// note"] == .comment)
    }

    @Test func swiftNumbersAndAttributes() {
        let result = kinds("@MainActor var count = 42", "swift")

        #expect(result["@MainActor"] == .attribute)
        #expect(result["42"] == .number)
    }

    @Test func objectiveC() {
        let result = kinds("#import <UIKit/UIKit.h>", "objc")

        #expect(result["#import"] == .meta)
        #expect(kinds("@interface Foo : NSObject", "objective-c")["@interface"] == .keyword)
    }

    @Test func json() {
        let result = kinds("\"key\": \"value\", \"n\": 3, \"ok\": true", "json")

        #expect(result["\"key\""] == .attribute)
        #expect(result["\"value\""] == .string)
        #expect(result["3"] == .number)
        #expect(result["true"] == .keyword)
    }

    @Test func yaml() {
        let result = kinds("name: slate # app", "yml")

        #expect(result["name"] == .attribute)
        #expect(result[" # app"] == .comment)
    }

    @Test func shell() {
        let result = kinds("export PATH=\"$HOME/bin\" # add", "zsh")

        #expect(result["export"] == .keyword)
        #expect(result["\"$HOME/bin\""] == .string)
    }

    @Test func diff() {
        #expect(kinds("+added line", "diff")["+added line"] == .added)
        #expect(kinds("-removed", "patch")["-removed"] == .removed)
        #expect(kinds("@@ -1,2 +1,2 @@", "diff")["@@ -1,2 +1,2 @@"] == .meta)
    }

    @Test func log() {
        let result = kinds("2026-10-16 10:01:02 ERROR failed", "log")

        #expect(result["2026-10-16 10:01:02"] == .number)
        #expect(result["ERROR"] == .removed)
    }

    @Test func unknownLanguageIsPlain() {
        #expect(CodeHighlighter.language(named: "brainfuck").name == "plain")
        #expect(CodeHighlighter.tokens(in: "let x", language: .plain).isEmpty)
    }
}
