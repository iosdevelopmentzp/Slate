import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite struct VaultBootstrapTests {
    @Test func newVaultGetsOneFolderAndAWelcomeNote() throws {
        let folder = try TemporaryDirectory()
        let root = folder.url.appendingPathComponent("Slate")

        let isNew = try VaultBootstrap(root: root).prepare(now: Date(), timeZone: .gmt)

        #expect(isNew)
        let names = Set(try FileManager.default.contentsOfDirectory(atPath: root.path))
        #expect(names == ["Notes", "_attachments", ".slate"])
        let welcome = try String(contentsOf: root.appendingPathComponent("Notes/Welcome to Slate.md"), encoding: .utf8)
        #expect(welcome.contains("title: Welcome to Slate"))
        #expect(welcome.contains("⌘N"))
    }

    @Test func existingVaultIsLeftAloneExceptStaleTemporaryFiles() throws {
        let folder = try TemporaryDirectory()
        _ = try folder.write("{}", to: ".slate/spaces.json")
        let stale = try folder.write("x", to: "Inbox/.A.md.slate-tmp")
        let fresh = try folder.write("y", to: "Inbox/.B.md.slate-tmp")
        let now = Date()
        try FileManager.default.setAttributes([.modificationDate: now.addingTimeInterval(-7_200)], ofItemAtPath: stale.path)

        let isNew = try VaultBootstrap(root: folder.url).prepare(now: now, timeZone: .gmt)

        #expect(isNew == false)
        #expect(FileManager.default.fileExists(atPath: folder.path("Tasks")) == false)
        #expect(FileManager.default.fileExists(atPath: stale.path) == false)
        #expect(FileManager.default.fileExists(atPath: fresh.path))
    }
}
