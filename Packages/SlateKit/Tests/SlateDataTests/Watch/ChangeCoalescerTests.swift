import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite struct ChangeCoalescerTests {
    private let root = URL(fileURLWithPath: "/tmp/vault-test")

    private func classify(_ relative: String, isDirectory: Bool = false, rescan: Bool = false) -> ChangeCoalescer.Classification {
        ChangeCoalescer.classify(ChangeCoalescer.Event(path: root.path + "/" + relative, isDirectory: isDirectory, needsRescan: rescan), root: root)
    }

    @Test func notesUnderASpaceArePaths() {
        #expect(classify("Inbox/A.md") == .file(VaultPath(rawValue: "Inbox/A.md")))
        #expect(classify("Notes/Swift/B.md") == .file(VaultPath(rawValue: "Notes/Swift/B.md")))
    }

    @Test func ignoredNamesAreDropped() {
        #expect(classify("Inbox/.DS_Store") == .ignore)
        #expect(classify("Inbox/.A.md.slate-tmp") == .ignore)
        #expect(classify(".trash/Inbox/A.md") == .ignore)
        #expect(classify(".git/index") == .ignore)
        #expect(classify(".obsidian/app.json") == .ignore)
        #expect(classify("_attachments/a.png") == .ignore)
        #expect(classify("Inbox/image.png") == .file(VaultPath(rawValue: "Inbox/image.png")))
        #expect(classify("Inbox/Other.md.sb-b6ceb2a3-R5wp7x") == .ignore)
        #expect(classify("Inbox/draft.txt~") == .ignore)
        #expect(classify("Inbox/upload.tmp") == .ignore)
    }

    @Test func foldersConfigAndTemplatesNeedARescan() {
        #expect(classify("Reading", isDirectory: true) == .rescan)
        #expect(classify("Notes/Swift", isDirectory: true) == .rescan)
        #expect(classify(".slate/spaces.json") == .rescan)
        #expect(classify("_templates/task.md") == .rescan)
        #expect(classify("Inbox/A.md", rescan: true) == .rescan)
    }

    @Test func privatePrefixMatchesForMissingFiles() {
        let temporary = URL(fileURLWithPath: "/var/folders/x/vault")

        #expect(ChangeCoalescer.relativePath("/private/var/folders/x/vault/Inbox/Gone.md", root: temporary) == "Inbox/Gone.md")
    }

    @Test func theRootFolderItselfIsIgnored() {
        #expect(ChangeCoalescer.classify(ChangeCoalescer.Event(path: root.path, isDirectory: true, needsRescan: false), root: root) == .ignore)
    }

    @Test func pathsOutsideTheVaultAreIgnoredAndCaseDoesNotMatter() {
        #expect(ChangeCoalescer.classify(ChangeCoalescer.Event(path: "/elsewhere/A.md", isDirectory: false, needsRescan: false), root: root) == .ignore)
        #expect(ChangeCoalescer.relativePath("/TMP/Vault-Test/Inbox/A.md", root: root) != nil)
    }

    @Test func flushGroupsPathsAndDropsOwnWrites() throws {
        let folder = try TemporaryDirectory()
        let own = try folder.write("mine", to: "Inbox/Own.md")
        _ = try folder.write("theirs", to: "Inbox/Other.md")
        let writes = OwnWrites()
        writes.record(VaultPath(rawValue: "Inbox/Own.md"), hash: .of(Data("mine".utf8)))
        let emitted = CallbackRecorder<VaultChange>()
        let coalescer = ChangeCoalescer(root: folder.url, ownWrites: writes) { emitted.append($0) }

        coalescer.record([
            ChangeCoalescer.Event(path: own.path, isDirectory: false, needsRescan: false),
            ChangeCoalescer.Event(path: folder.path("Inbox/Other.md"), isDirectory: false, needsRescan: false),
            ChangeCoalescer.Event(path: folder.path("Inbox/Other.md"), isDirectory: false, needsRescan: false),
        ])
        coalescer.flush()

        #expect(emitted.values == [.paths([VaultPath(rawValue: "Inbox/Other.md")])])
    }

    @Test func rescanWinsOverPaths() throws {
        let folder = try TemporaryDirectory()
        let emitted = CallbackRecorder<VaultChange>()
        let coalescer = ChangeCoalescer(root: folder.url, ownWrites: OwnWrites()) { emitted.append($0) }

        coalescer.record([
            ChangeCoalescer.Event(path: folder.path("Inbox/A.md"), isDirectory: false, needsRescan: false),
            ChangeCoalescer.Event(path: folder.path("Reading"), isDirectory: true, needsRescan: false),
        ])
        coalescer.flush()
        coalescer.flush()

        #expect(emitted.values == [.rescan])
    }
}
