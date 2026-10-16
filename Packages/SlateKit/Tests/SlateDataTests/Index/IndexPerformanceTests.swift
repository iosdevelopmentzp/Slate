import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite(.enabled(if: ProcessInfo.processInfo.environment["SLATE_PERF_VAULT"] != nil))
struct IndexPerformanceTests {
    @Test func fullScanAndSearchOfAGeneratedVault() async throws {
        let root = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["SLATE_PERF_VAULT"]), isDirectory: true)
        let support = try TemporaryDirectory()
        let indexURL = ProcessInfo.processInfo.environment["SLATE_PERF_INDEX"].map { URL(fileURLWithPath: $0) } ?? support.url.appendingPathComponent("index.sqlite")
        let index = try GRDBSearchIndex.open(at: indexURL, vaultPath: root.path)
        let (spyPorts, spies) = Ports.spies()
        _ = spies
        let ports = Ports(
            keyValues: spyPorts.keyValues,
            files: FileVaultStore(root: root, ownWrites: OwnWrites()),
            index: index,
            builder: IndexedNoteBuilder(),
            watcher: spyPorts.watcher,
            trash: spyPorts.trash,
            templates: spyPorts.templates,
            config: spyPorts.config,
            clock: spyPorts.clock,
            attachments: spyPorts.attachments,
            capture: spyPorts.capture,
            workspace: spyPorts.workspace,
            loginItem: spyPorts.loginItem,
            system: spyPorts.system,
            history: spyPorts.history,
            journal: spyPorts.journal
        )
        let reindex = UseCases(ports: ports).reindex
        let clock = ContinuousClock()
        var report = ReindexReport()
        let full = try await clock.measure {
            report = try await reindex.execute(.all)
        }
        let again = try await clock.measure {
            _ = try await reindex.execute(.all)
        }
        let query = SearchQueryParser.parse("retain cycle", now: Date(), timeZone: .current)
        var searches: [Duration] = []
        var count = 0
        for _ in 0..<20 {
            searches.append(try await clock.measure {
                count = try await index.search(query, limit: 50).count
            })
        }
        let sorted = searches.sorted()
        print("index timing: notes=\(report.indexed.count) full=\(full) unchanged=\(again) search median=\(sorted[10]) worst=\(sorted[19]) hits=\(count)")
        #expect(full < .seconds(20))
        #expect(sorted[10] < .milliseconds(50))
    }
}
