import Foundation
import Testing
@testable import SlateDomain

@Suite struct FileNamePolicyTests {
    @Test func slashesAndColonsBecomeDashesAndHiddenNamesAreRefused() {
        #expect(FileNamePolicy.cleaned(" a/b:c.txt ") == "a-b-c.txt")
        #expect(FileNamePolicy.cleaned(".env") == nil)
        #expect(FileNamePolicy.cleaned("  ") == nil)
    }

    @Test func renameKeepsTheExtensionWhenItIsLeftOut() {
        #expect(FileNamePolicy.renamed("crash", keeping: "log.txt") == "crash.txt")
        #expect(FileNamePolicy.renamed("crash.log", keeping: "log.txt") == "crash.log")
        #expect(FileNamePolicy.renamed("notes", keeping: "Makefile") == "notes")
    }

    @Test func takenNameGetsANumberBeforeTheExtension() {
        #expect(FileNamePolicy.unique("a.png", among: ["b.png"]) == "a.png")
        #expect(FileNamePolicy.unique("a.png", among: ["A.png", "a 2.png"]) == "a 3.png")
        #expect(FileNamePolicy.unique("README", among: ["README"]) == "README 2")
    }
}
