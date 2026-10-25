import Foundation
import SlateTestSupport
import Testing
@testable import SlateCLI

@Suite struct ExecutableStampTests {
    private let folder: TemporaryDirectory

    init() throws {
        folder = try TemporaryDirectory()
    }

    private func write(_ name: String, _ text: String) throws -> URL {
        let url = folder.url.appendingPathComponent(name)
        try Data(text.utf8).write(to: url)
        return url
    }

    @Test func aFileMovedOverThePathReplacesIt() throws {
        let tool = try write("slate", "old")
        let stamp = try #require(ExecutableStamp(path: tool.path))
        let new = try write("slate.new", "new")

        #expect(stamp.isReplaced == false)
        _ = try FileManager.default.replaceItemAt(tool, withItemAt: new)
        #expect(stamp.isReplaced)
    }

    @Test func aMissingFileHasNoStampAndAGoneFileIsNotReplaced() throws {
        let tool = try write("slate", "old")
        let stamp = try #require(ExecutableStamp(path: tool.path))
        try FileManager.default.removeItem(at: tool)

        #expect(ExecutableStamp(path: tool.path) == nil)
        #expect(stamp.isReplaced == false)
    }
}
