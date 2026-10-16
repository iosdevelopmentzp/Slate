import Testing
@testable import SlatePresentation

@MainActor
@Suite struct ToasterTests {
    @Test func copyWritesTheValueAndShowsTheLabel() {
        var written: [String] = []
        let toaster = Toaster { written.append($0) }

        toaster.copy("ABC-123-fix-the-crash", label: "Branch")

        #expect(written == ["ABC-123-fix-the-crash"])
        #expect(toaster.text == "Branch copied")
        #expect(toaster.actionTitle == nil)
    }

    @Test func aNewMessageReplacesTheOldOne() {
        let toaster = Toaster { _ in }

        toaster.show("First", action: ToastAction(title: "Undo") {})
        toaster.show("Second")

        #expect(toaster.text == "Second")
        #expect(toaster.actionTitle == nil)
    }

    @Test func actionRunsOnceAndDismisses() {
        let toaster = Toaster { _ in }
        var runs = 0
        toaster.show("Moved to the Trash", action: ToastAction(title: "Undo") { runs += 1 })

        #expect(toaster.actionTitle == "Undo")
        toaster.performAction()
        toaster.performAction()

        #expect(runs == 1)
        #expect(toaster.text == nil)
    }
}
