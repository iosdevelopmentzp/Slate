import Foundation
import SlateDomain
import Testing
@testable import SlatePresentation

@Suite struct NavigationHistoryTests {
    private func place(_ note: String?, file: String? = nil) -> NavigationPlace {
        NavigationPlace(source: .all, note: note.map(NoteID.init(rawValue:)), file: file.map(VaultPath.init(rawValue:)))
    }

    @Test func backAndForwardWalkTheVisitedPlaces() {
        var history = NavigationHistory()
        history.visit(place("a"))
        history.visit(place("b"))
        history.visit(place(nil, file: "Notes/x.pdf"))

        #expect(history.goBack { _ in true } == place("b"))
        #expect(history.goBack { _ in true } == place("a"))
        #expect(history.canGoBack == false)
        #expect(history.goForward { _ in true } == place("b"))
        #expect(history.canGoForward)
    }

    @Test func aNewVisitClearsForward() {
        var history = NavigationHistory()
        history.visit(place("a"))
        history.visit(place("b"))
        _ = history.goBack { _ in true }

        history.visit(place("c"))

        #expect(history.canGoForward == false)
        #expect(history.goBack { _ in true } == place("a"))
    }

    @Test func theSameNoteAndNoSelectionAreNotNewPlaces() {
        var history = NavigationHistory()
        history.visit(place("a"))
        history.visit(place(nil))
        history.visit(place("a"))

        #expect(history.canGoBack == false)
    }

    @Test func goneNotesAreSkipped() {
        var history = NavigationHistory()
        history.visit(place("a"))
        history.visit(place("gone"))
        history.visit(place("c"))

        #expect(history.goBack { $0.note?.rawValue != "gone" } == place("a"))
    }
}
