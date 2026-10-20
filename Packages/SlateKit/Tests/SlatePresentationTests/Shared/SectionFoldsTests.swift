import Foundation
import SlateDomain
import SlateMocks
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct SectionFoldsTests {
    @Test func sectionsSurviveARestart() {
        let store = InMemoryKeyValueStore()
        SectionFolds(store: store).set(["1 Context", "2 Detail"], for: NoteID(rawValue: "a"))

        let folds = SectionFolds(store: store)

        #expect(folds.sections(for: NoteID(rawValue: "a")) == ["1 Context", "2 Detail"])
        #expect(folds.sections(for: NoteID(rawValue: "b")) == [])
        #expect(folds.sections(for: nil) == [])
    }

    @Test func expandingEverySectionForgetsTheNote() {
        let store = InMemoryKeyValueStore()
        let folds = SectionFolds(store: store)
        folds.set(["1 Context"], for: NoteID(rawValue: "a"))

        folds.set([], for: NoteID(rawValue: "a"))

        #expect(store.decode([String: [String]].self, forKey: "editor.collapsedSections") == [:])
    }
}
