import Foundation
import SlateDomain
import SlateTestSupport
import Testing
@testable import SlateData

@Suite(.tags(.integration)) struct FileVaultStoreIntegrationTests {
    @Test func writesStayWholeWhileAnotherProcessTouchesTheFile() async throws {
        let folder = try TemporaryDirectory()
        let store = FileVaultStore(root: folder.url, ownWrites: OwnWrites())
        let path = VaultPath(rawValue: "Inbox/A.md")
        _ = try folder.write("start", to: path.rawValue)
        let runner = ShellRunner(recorder: SpyCommandRecorder())
        let contents = (0..<40).map { String(repeating: "\($0 % 10)", count: 20_000) }

        async let touching = runner.run("sh", ["-c", "for i in $(seq 200); do touch '\(folder.path(path.rawValue))'; done"], cwd: nil)
        for text in contents {
            _ = try await store.write(path, data: Data(text.utf8), expected: nil)
            let read = String(decoding: try await store.read(path).data, as: UTF8.self)
            #expect(contents.contains(read))
        }
        _ = try await touching

        #expect(String(decoding: try await store.read(path).data, as: UTF8.self) == contents.last)
    }
}
