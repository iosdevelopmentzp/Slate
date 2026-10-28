import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@MainActor
@Suite struct SearchResultMapperTests {
    @Test func aFileHitShowsItsNameTextAndFolder() {
        let hit = FileHit(path: VaultPath(rawValue: "MyApp/Task/crash.log"), excerpt: "Fatal error", rank: 0)

        let model = SearchResultMapper.model(for: hit, words: ["fatal"])

        #expect(model.id == hit.path)
        #expect(String(model.name.characters) == "crash.log")
        #expect(String(model.excerpt.characters) == "Fatal error")
        #expect(model.folder == "MyApp/Task")
    }

    @Test func matchedWordsAreStrong() {
        let text = SearchResultMapper.highlighted("Fatal error", words: ["fatal"])

        let strong = text.runs.filter { $0.inlinePresentationIntent == .stronglyEmphasized }.map { String(text[$0.range].characters) }
        #expect(strong == ["Fatal"])
    }
}
