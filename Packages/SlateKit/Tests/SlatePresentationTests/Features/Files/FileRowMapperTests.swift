import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct FileRowMapperTests {
    @Test func nameDetailAndImageKindComeFromTheFile() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let meta = FileMeta(path: VaultPath(rawValue: "MyApp/Task/Screen.PNG"), created: now, modified: now, size: 2048)

        let model = FileRowMapper.model(for: meta, now: now)

        #expect(model.id == meta.path)
        #expect(model.name == "Screen.PNG")
        #expect(model.detail.isEmpty == false)
        #expect(model.isImage)
        #expect(FileRowMapper.model(for: FileMeta(path: VaultPath(rawValue: "MyApp/a.log"), created: now, modified: now, size: 1), now: now).isImage == false)
    }
}
