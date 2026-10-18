import Foundation
import SlateDomain
import Testing
@testable import SlateData

@Suite struct GitChangesParserTests {
    @Test func everyBlockIsAVersionWithItsFiles() {
        let output = "\u{1E}aaaaaaa1\t1800000000\tversion: done\n\nD\tMyApp/crash.log\n\u{1E}bbbbbbb2\t1799999000\tagent: add_file x\n\nM\tMyApp/Plan.md\nA\tMyApp/x.png\nR087\tMyApp/Old.md\tMyApp/New.md\n"

        let changes = GitChangesParser.changes(from: output)

        #expect(changes.map(\.snapshot.message) == ["version: done", "agent: add_file x"])
        #expect(changes[0].files == [ChangedFile(path: VaultPath(rawValue: "MyApp/crash.log"), kind: .removed)])
        #expect(changes[1].files == [
            ChangedFile(path: VaultPath(rawValue: "MyApp/Plan.md"), kind: .changed),
            ChangedFile(path: VaultPath(rawValue: "MyApp/x.png"), kind: .added),
            ChangedFile(path: VaultPath(rawValue: "MyApp/Old.md"), kind: .removed),
            ChangedFile(path: VaultPath(rawValue: "MyApp/New.md"), kind: .added),
        ])
    }

    @Test func emptyOutputHasNoChanges() {
        #expect(GitChangesParser.changes(from: "").isEmpty)
    }
}
