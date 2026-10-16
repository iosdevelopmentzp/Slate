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
