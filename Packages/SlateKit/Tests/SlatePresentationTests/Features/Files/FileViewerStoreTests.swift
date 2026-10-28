import Foundation
import SlateDomain
import SlateMocks
import SlateTestSupport
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct FileViewerStoreTests {
    private let harness = StoreHarness()
    private let code = VaultPath(rawValue: "Work/App.swift")

    private var viewer: FileViewerStore {
        harness.fileViewer
    }

    @Test func aTextFileOpensAsText() async {
        harness.spies.files.seed(code, "let a = 1")

        await viewer.open(code)

        #expect(viewer.content == .text)
        #expect(viewer.text == "let a = 1")
        #expect(viewer.meta?.path == code)
        #expect(viewer.url == URL(fileURLWithPath: "/vault/Work/App.swift"))
    }

    @Test func aDocumentOpensAsPreviewWithoutReadingIt() async {
        let pdf = VaultPath(rawValue: "Work/spec.pdf")
        harness.spies.files.seed(pdf, "%PDF-1.7")

        await viewer.open(pdf)

        #expect(viewer.content == .preview)
        #expect(harness.spies.files.calls.contains(.read(pdf)) == false)
    }

    @Test func binaryDataOpensAsPreview() async {
        let blob = VaultPath(rawValue: "Work/data.bin2")
        harness.spies.files.seed(blob, "a\u{0}b")

        await viewer.open(blob)

        #expect(viewer.content == .preview)
    }

    @Test func aMissingFileSaysSo() async {
        await viewer.open(VaultPath(rawValue: "Work/gone.txt"))

        #expect(viewer.content == .missing)
    }

    @Test func anEditIsWrittenOnFlush() async {
        let hash = harness.spies.files.seed(code, "let a = 1")
        await viewer.open(code)

        viewer.text = "let a = 2"
        await viewer.flush()

        #expect(harness.spies.files.text(at: code) == "let a = 2")
        #expect(harness.spies.files.calls.contains(.write(code, expected: hash)))
    }

    @Test func openingAnotherFileSavesTheEditFirst() async {
        harness.spies.files.seed(code, "let a = 1")
        await viewer.open(code)
        viewer.text = "let a = 2"

        await viewer.open(nil)

        #expect(harness.spies.files.text(at: code) == "let a = 2")
        #expect(viewer.path == nil)
        #expect(viewer.text.isEmpty)
    }

    @Test func aChangeOnDiskReloadsWhenThereIsNoEdit() async throws {
        harness.spies.files.seed(code, "let a = 1")
        await viewer.open(code)

        harness.spies.files.seed(code, "let a = 3")
        harness.events.post(.vaultChanged([code]))

        try await waitUntil { viewer.text == "let a = 3" }
        #expect(viewer.hasConflict == false)
    }

    @Test func aChangeOnDiskDuringAnEditIsAConflict() async throws {
        harness.spies.files.seed(code, "let a = 1")
        await viewer.open(code)
        viewer.text = "let a = 2"

        harness.spies.files.seed(code, "let a = 3")
        harness.events.post(.vaultChanged([code]))

        try await waitUntil { viewer.hasConflict }
        await viewer.flush()
        #expect(harness.spies.files.text(at: code) == "let a = 3")
    }

    @Test func keepMineWritesTheEditOverTheDisk() async throws {
        harness.spies.files.seed(code, "let a = 1")
        await viewer.open(code)
        viewer.text = "let a = 2"
        harness.spies.files.seed(code, "let a = 3")
        await viewer.flush()
        #expect(viewer.hasConflict)

        await viewer.keepMine()

        #expect(viewer.hasConflict == false)
        #expect(harness.spies.files.text(at: code) == "let a = 2")
    }

    @Test func takeTheirsLoadsTheDisk() async {
        harness.spies.files.seed(code, "let a = 1")
        await viewer.open(code)
        viewer.text = "let a = 2"
        harness.spies.files.seed(code, "let a = 3")
        await viewer.flush()

        await viewer.takeTheirs()

        #expect(viewer.hasConflict == false)
        #expect(viewer.text == "let a = 3")
    }

    @Test func pendingSaveExistsOnlyForAnEdit() async {
        harness.spies.files.seed(code, "let a = 1")
        await viewer.open(code)
        #expect(viewer.pendingSave() == nil)

        viewer.text = "let a = 2"
        await viewer.pendingSave()?()

        #expect(harness.spies.files.text(at: code) == "let a = 2")
    }
}
