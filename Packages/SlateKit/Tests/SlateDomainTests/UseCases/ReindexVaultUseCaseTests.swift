import Foundation
import SlateTestSupport
import Testing
@testable import SlateDomain

@Suite struct ReindexVaultUseCaseTests {
    private let ports: Ports
    private let spies: PortSpies

    init() {
        (ports, spies) = Ports.spies()
    }

    @Test func fullScanIndexesEveryNoteAndRemovesMissingOnes() async throws {
        let a = VaultPath(rawValue: "Inbox/A.md")
        let b = VaultPath(rawValue: "Tasks/B.md")
        spies.files.seed(a, NoteText.make(id: "a", title: "A", body: ""))
        spies.files.seed(b, NoteText.make(id: "b", title: "B", body: ""))
        let gone = VaultPath(rawValue: "Inbox/Gone.md")
        try await spies.index.upsert(IndexedNote(
            summary: NoteSummary(id: NoteID(rawValue: "g"), path: gone, title: "Gone", updated: .now, preview: ""),
            state: IndexedFileState(modified: .now, size: 0, hash: ContentHash(rawValue: "g"))
        ))

        let report = try await UseCases(ports: ports).reindex.execute(.all)

        #expect(Set(report.indexed) == [a, b])
        #expect(report.removed == [gone])
        #expect(Set(spies.index.indexed.keys) == [a, b])
    }

    @Test func fullScanReportsProgressAfterEachBatch() async throws {
        for number in 0..<450 {
            spies.files.seed(VaultPath(rawValue: "Inbox/N\(number).md"), NoteText.make(id: "n\(number)", title: "N\(number)", body: ""))
        }
        let steps = ProgressSteps()

        _ = try await UseCases(ports: ports).reindex.execute(.all) { done, total in steps.add(done, total) }

        #expect(await steps.all == [[200, 450], [400, 450], [450, 450]])
    }

    @Test func otherFilesAreIndexedWithTheirTextOrOnlyTheirName() async throws {
        let code = VaultPath(rawValue: "Work/App.swift")
        let image = VaultPath(rawValue: "Work/shot.png")
        spies.files.seed(code, "let player = 1")
        spies.files.seed(image, "png")
        spies.files.seed(VaultPath(rawValue: "_attachments/a.txt"), "hidden")

        let report = try await UseCases(ports: ports).reindex.execute(.all)

        #expect(Set(report.files) == [code, image])
        #expect(spies.index.indexedFiles[code]?.text == "let player = 1")
        #expect(spies.index.indexedFiles[image]?.text == "")
        #expect(spies.files.calls.contains(.read(image)) == false)
    }

    @Test func unchangedOtherFilesAreSkippedAndMissingOnesRemoved() async throws {
        let code = VaultPath(rawValue: "Work/App.swift")
        let log = VaultPath(rawValue: "Work/crash.log")
        spies.files.seed(code, "let a = 1")
        spies.files.seed(log, "boom")
        let useCase = UseCases(ports: ports).reindex
        _ = try await useCase.execute(.all)
        _ = try await spies.files.trashFile(log)

        let report = try await useCase.execute(.all)

        #expect(report.files == [log])
        #expect(spies.index.calls.contains(.removeFile(log)))
        #expect(Set(spies.index.indexedFiles.keys) == [code])
    }

    @Test func changedPathsIndexAndRemoveOtherFiles() async throws {
        let code = VaultPath(rawValue: "Work/App.swift")
        let gone = VaultPath(rawValue: "Work/old.txt")
        spies.files.seed(gone, "old")
        let useCase = UseCases(ports: ports).reindex
        _ = try await useCase.execute(.all)
        _ = try await spies.files.trashFile(gone)
        spies.files.seed(code, "let a = 1")

        let report = try await useCase.execute(.paths([code, gone, VaultPath(rawValue: "Work/Sub")]))

        #expect(Set(report.files) == [code, gone])
        #expect(Set(spies.index.indexedFiles.keys) == [code])
    }

    @Test func unchangedFilesAreSkipped() async throws {
        let a = VaultPath(rawValue: "Inbox/A.md")
        spies.files.seed(a, NoteText.make(id: "a", title: "A", body: ""))
        let useCase = UseCases(ports: ports).reindex
        _ = try await useCase.execute(.all)

        let report = try await useCase.execute(.all)

        #expect(report.indexed.isEmpty)
        #expect(report.removed.isEmpty)
    }

    @Test func touchedFileWithTheSameBytesOnlyUpdatesTheState() async throws {
        let a = VaultPath(rawValue: "Inbox/A.md")
        let text = NoteText.make(id: "a", title: "A", body: "")
        spies.files.seed(a, text)
        let useCase = UseCases(ports: ports).reindex
        _ = try await useCase.execute(.all)
        spies.files.seed(a, text)

        let report = try await useCase.execute(.paths([a]))

        #expect(report.indexed.isEmpty)
        #expect(spies.index.calls.last == .updateState(a))
    }

    @Test func pathScopeRemovesDeletedFilesAndIgnoresNonNotes() async throws {
        let a = VaultPath(rawValue: "Inbox/A.md")
        spies.files.seed(a, NoteText.make(id: "a", title: "A", body: ""))
        let useCase = UseCases(ports: ports).reindex
        _ = try await useCase.execute(.all)
        try await spies.files.move(from: a, to: VaultPath(rawValue: ".trash/Inbox/A.md"))

        let report = try await useCase.execute(.paths([a, VaultPath(rawValue: "_templates/task.md")]))

        #expect(report.removed == [a])
        #expect(spies.index.indexed.isEmpty)
    }

    @Test func unreadableFileIsReportedAndTheScanGoesOn() async throws {
        spies.files.seed(VaultPath(rawValue: "Inbox/A.md"), NoteText.make(id: "a", title: "A", body: ""))
        let bad = VaultPath(rawValue: "Inbox/Bad.md")
        try await spies.files.create(bad, data: Data([0xFF, 0xFE, 0xD8]))

        let report = try await UseCases(ports: ports).reindex.execute(.all)

        #expect(report.failed == [bad])
        #expect(report.indexed == [VaultPath(rawValue: "Inbox/A.md")])
    }
}

@MainActor
private final class ProgressSteps {
    private(set) var all: [[Int]] = []

    func add(_ done: Int, _ total: Int) {
        all.append([done, total])
    }
}
