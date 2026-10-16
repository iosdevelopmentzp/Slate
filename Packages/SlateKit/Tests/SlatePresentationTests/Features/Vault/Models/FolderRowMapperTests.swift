import Foundation
import SlateDomain
import SlateUI
import Testing
@testable import SlatePresentation

@Suite struct FolderRowMapperTests {
    private let notes = SpaceName(rawValue: "Notes")

    @Test func folderGetsItsColourIconAndCount() {
        let space = Space(folder: SpaceName(rawValue: "Ideas"), icon: "lightbulb.fill", color: .yellow)

        let model = FolderRowMapper.model(for: space, count: 4, defaultFolder: notes)

        #expect(model.title == "Ideas")
        #expect(model.icon == "lightbulb.fill")
        #expect(model.tint == .yellow)
        #expect(model.count == 4)
        #expect(model.canDelete)
        #expect(model.deleteQuestion == "Delete \u{201C}Ideas\u{201D}? Its 4 notes move to Notes.")
    }

    @Test func plainOrMissingIconBecomesAFilledFolder() {
        #expect(FolderRowMapper.model(for: Space(folder: notes, icon: "folder"), count: 0, defaultFolder: notes).icon == "folder.fill")
        #expect(FolderRowMapper.model(for: Space(folder: notes), count: 0, defaultFolder: notes).icon == "folder.fill")
    }

    @Test func theDefaultFolderCannotBeDeleted() {
        #expect(FolderRowMapper.model(for: Space(folder: notes), count: 0, defaultFolder: notes).canDelete == false)
    }

    @Test func questionSaysHowManyNotesMove() {
        let work = Space(folder: SpaceName(rawValue: "Work"))

        #expect(FolderRowMapper.model(for: work, count: 0, defaultFolder: notes).deleteQuestion == "Delete \u{201C}Work\u{201D}? It has no notes.")
        #expect(FolderRowMapper.model(for: work, count: 1, defaultFolder: notes).deleteQuestion == "Delete \u{201C}Work\u{201D}? Its note moves to Notes.")
    }

    @Test func everyColourHasATintAndATitle() {
        #expect(Set(SpaceColor.allCases.map(FolderTint.tint)).count == SpaceColor.allCases.count)
        #expect(SpaceColor.allCases.map(FolderTint.title).allSatisfy { $0.isEmpty == false })
    }
}
