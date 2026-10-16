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
    }

    @Test func aNewMessageReplacesTheOldOne() {
        let toaster = Toaster { _ in }

        toaster.show("First")
        toaster.show("Second")

        #expect(toaster.text == "Second")
    }

    @Test func dismissClearsTheMessage() {
        let toaster = Toaster { _ in }
        toaster.show("Saved")

        toaster.dismiss()

        #expect(toaster.text == nil)
    }
}
