import Foundation
import Testing
@testable import SlateDomain

@Suite struct FileKindPolicyTests {
    @Test func codeAndUnknownNamesMayBeText() {
        #expect(FileKindPolicy.mayBeText(VaultPath(rawValue: "Work/App.swift"), size: 100))
        #expect(FileKindPolicy.mayBeText(VaultPath(rawValue: "Work/Makefile"), size: 100))
        #expect(FileKindPolicy.mayBeText(VaultPath(rawValue: "Work/crash.log"), size: 100))
    }

    @Test func documentsMediaAndArchivesAreShownAsPreview() {
        #expect(FileKindPolicy.mayBeText(VaultPath(rawValue: "Work/spec.PDF"), size: 100) == false)
        #expect(FileKindPolicy.mayBeText(VaultPath(rawValue: "Work/shot.png"), size: 100) == false)
        #expect(FileKindPolicy.mayBeText(VaultPath(rawValue: "Work/page.html"), size: 100) == false)
        #expect(FileKindPolicy.mayBeText(VaultPath(rawValue: "Work/logs.zip"), size: 100) == false)
    }

    @Test func aFileOverTheLimitIsNeverText() {
        #expect(FileKindPolicy.mayBeText(VaultPath(rawValue: "Work/big.txt"), size: FileKindPolicy.textLimit + 1) == false)
    }

    @Test func utf8WithoutZeroBytesIsText() {
        #expect(FileKindPolicy.text(from: Data("let a = 1\nПривіт".utf8)) == "let a = 1\nПривіт")
        #expect(FileKindPolicy.text(from: Data()) == "")
    }

    @Test func theByteOrderMarkIsDropped() {
        #expect(FileKindPolicy.text(from: Data([0xEF, 0xBB, 0xBF]) + Data("a".utf8)) == "a")
    }

    @Test func zeroBytesOrBrokenUTF8AreNotText() {
        #expect(FileKindPolicy.text(from: Data([0x61, 0x00, 0x62])) == nil)
        #expect(FileKindPolicy.text(from: Data([0x61, 0xFF, 0xFE])) == nil)
    }
}
