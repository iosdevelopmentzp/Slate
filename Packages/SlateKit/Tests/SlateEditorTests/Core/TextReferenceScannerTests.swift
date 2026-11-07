import Foundation
import Testing
@testable import SlateEditor

@MainActor
@Suite struct TextReferenceScannerTests {
    private let all: TextReference.Kinds = [.files, .tickets, .mergeRequests, .commits]

    private func found(_ text: String, _ kinds: TextReference.Kinds? = nil) -> [TextReference] {
        TextReferenceScanner.references(in: text, kinds: kinds ?? all).map(\.reference)
    }

    @Test func filePathsWithAndWithoutALine() {
        #expect(found("See Sources/Login/LoginView.swift:42 and Info.plist.") == [.file(path: "Sources/Login/LoginView.swift", line: 42), .file(path: "Info.plist", line: nil)])
    }

    @Test func ticketsMergeRequestsAndCommits() {
        #expect(found("ABC-123 in !45, fixed in a1b2c3d4.") == [.ticket("ABC-123"), .mergeRequest(45), .commit("a1b2c3d4")])
    }

    @Test func wordsAndNumbersAreNotCommits() {
        #expect(found("decade 1234567 facade feedbeef", [.commits]).isEmpty)
    }

    @Test func addressesAreLeftToTheLinks() {
        #expect(found("https://example.com/a/File.swift and https://example.atlassian.net/browse/ABC-1").isEmpty)
    }

    @Test func onlyTheAskedKinds() {
        #expect(found("ABC-123 File.swift", [.files]) == [.file(path: "File.swift", line: nil)])
    }
}
