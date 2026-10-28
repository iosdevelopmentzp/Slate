import Foundation
import Testing
@testable import SlateDomain

@Suite struct FileIndexPolicyTests {
    private let stamp = FileStamp(modified: Date(timeIntervalSince1970: 1), size: 1)

    @Test func onlyOtherFilesInsideFoldersAreIndexed() {
        #expect(FileIndexPolicy.isIndexed(VaultPath(rawValue: "Work/App.swift")))
        #expect(FileIndexPolicy.isIndexed(VaultPath(rawValue: "Work/Sub/spec.pdf")))
        #expect(FileIndexPolicy.isIndexed(VaultPath(rawValue: "Work/Note.md")) == false)
        #expect(FileIndexPolicy.isIndexed(VaultPath(rawValue: "_attachments/shot.png")) == false)
        #expect(FileIndexPolicy.isIndexed(VaultPath(rawValue: ".slate/spaces.json")) == false)
        #expect(FileIndexPolicy.isIndexed(VaultPath(rawValue: "Work/.DS_Store")) == false)
        #expect(FileIndexPolicy.isIndexed(VaultPath(rawValue: "Work/.git/config")) == false)
        #expect(FileIndexPolicy.isIndexed(VaultPath(rawValue: "Work/a.log.slate-tmp")) == false)
        #expect(FileIndexPolicy.isIndexed(VaultPath(rawValue: "Root.txt")) == false)
    }

    @Test func contentIsReadForTextAndForPDFsUpToTheirLimits() {
        #expect(FileIndexPolicy.readsContent(VaultPath(rawValue: "Work/a.txt"), size: 10))
        #expect(FileIndexPolicy.readsContent(VaultPath(rawValue: "Work/spec.pdf"), size: FileIndexPolicy.pdfLimit))
        #expect(FileIndexPolicy.readsContent(VaultPath(rawValue: "Work/spec.pdf"), size: FileIndexPolicy.pdfLimit + 1) == false)
        #expect(FileIndexPolicy.readsContent(VaultPath(rawValue: "Work/shot.png"), size: 10) == false)
    }

    @Test func longTextIsCut() {
        let text = String(repeating: "a", count: FileIndexPolicy.textLength + 5)

        #expect(FileIndexPolicy.trimmed(text).count == FileIndexPolicy.textLength)
        #expect(FileIndexPolicy.trimmed("short") == "short")
    }

    @Test func onlyTextQueriesWithAFolderFilterReachFiles() {
        #expect(FileIndexPolicy.searchable(SearchQuery(terms: ["crash"])))
        #expect(FileIndexPolicy.searchable(SearchQuery(terms: ["crash"], filters: [.space("Work")])))
        #expect(FileIndexPolicy.searchable(SearchQuery(terms: ["crash"], filters: [.tag("ios")])) == false)
        #expect(FileIndexPolicy.searchable(SearchQuery(filters: [.space("Work")])) == false)
    }

    @Test func hitsMatchTheNameOrTheTextInTheFolder() {
        let files = [
            IndexedFile(path: VaultPath(rawValue: "Work/crash.log"), stamp: stamp, text: "Fatal error in the player"),
            IndexedFile(path: VaultPath(rawValue: "Work/App.swift"), stamp: stamp, text: "let player = Player()"),
            IndexedFile(path: VaultPath(rawValue: "Home/list.txt"), stamp: stamp, text: "milk"),
        ]

        #expect(FileIndexPolicy.hits(in: files, query: SearchQuery(terms: ["player"]), limit: 10).map(\.path.fileName) == ["App.swift", "crash.log"])
        #expect(FileIndexPolicy.hits(in: files, query: SearchQuery(terms: ["crash"]), limit: 10).map(\.path.fileName) == ["crash.log"])
        #expect(FileIndexPolicy.hits(in: files, query: SearchQuery(terms: ["milk"], filters: [.space("Work")]), limit: 10).isEmpty)
        #expect(FileIndexPolicy.hits(in: files, query: SearchQuery(terms: ["player"], excludedTerms: ["fatal"]), limit: 10).map(\.path.fileName) == ["App.swift"])
        #expect(FileIndexPolicy.hits(in: files, query: SearchQuery(terms: ["fatal"]), limit: 10).first?.excerpt.contains("Fatal") == true)
    }
}
