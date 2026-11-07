import Foundation
import Testing
import SlateDomain
import SlateEditor
import SlateTestSupport
@testable import SlatePresentation

@MainActor
@Suite struct EditorStoreReferencesTests {
    private let harness = StoreHarness()
    private let project = ProjectInfo(id: "p", repositories: ["/code/app"], remote: "gitlab.example.com/group/app")

    @Test func aFileOpensInTheProjectRepository() async {
        await harness.editor.openReference(.file(path: "Login/LoginView.swift", line: 42), project: project, ticketAddress: "")

        #expect(harness.spies.workspace.calls == [.openCode("Login/LoginView.swift", line: 42, roots: [URL(fileURLWithPath: "/code/app", isDirectory: true)])])
    }

    @Test func aMissingFileSaysSo() async {
        harness.spies.workspace.codeFound = false

        await harness.editor.openReference(.file(path: "Gone.swift", line: nil), project: project, ticketAddress: "")

        #expect(harness.toaster.text == "Slate did not find Gone.swift in the repository of this project.")
    }

    @Test func ticketsMergeRequestsAndCommitsOpenTheirAddresses() async {
        await harness.editor.openReference(.ticket("ABC-123"), project: nil, ticketAddress: "https://example.atlassian.net/browse/")
        await harness.editor.openReference(.mergeRequest(7), project: project, ticketAddress: "")
        await harness.editor.openReference(.commit("a1b2c3d"), project: project, ticketAddress: "")

        #expect(harness.spies.workspace.calls == [
            .open(URL(string: "https://example.atlassian.net/browse/ABC-123")!),
            .open(URL(string: "https://gitlab.example.com/group/app/-/merge_requests/7")!),
            .open(URL(string: "https://gitlab.example.com/group/app/commit/a1b2c3d")!),
        ])
    }
}
