import Foundation
import Testing
@testable import SlateEditor

@Suite struct CompletionContextTests {
    private func context(_ text: String) -> CompletionContext? {
        let ns = text as NSString
        return CompletionContext.at(ns.length, in: ns)
    }

    @Test func afterDoubleBracketsCompletesANote() {
        #expect(context("see [[") == CompletionContext(kind: .note, range: NSRange(location: 6, length: 0)))
        #expect(context("see [[Aud") == CompletionContext(kind: .note, range: NSRange(location: 6, length: 3)))
    }

    @Test func closedLinksAndAliasesDoNotComplete() {
        #expect(context("see [[Audio]] x") == nil)
        #expect(context("see [[Audio|al") == nil)
    }

    @Test func hashWithLettersCompletesATag() {
        #expect(context("a #au") == CompletionContext(kind: .tag, range: NSRange(location: 3, length: 2)))
        #expect(context("#au") == CompletionContext(kind: .tag, range: NSRange(location: 1, length: 2)))
    }

    @Test func hashInsideAWordDoesNotComplete() {
        #expect(context("a#au") == nil)
        #expect(context("plain") == nil)
    }
}
