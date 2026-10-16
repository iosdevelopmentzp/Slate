import Foundation
import Testing
@testable import SlatePresentation

@Suite struct SaveStatusTextTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func statesReadAsPlainWords() {
        #expect(SaveStatusText.text(for: .idle, now: now) == nil)
        #expect(SaveStatusText.text(for: .saving, now: now) == "saving…")
        #expect(SaveStatusText.text(for: .saved(now.addingTimeInterval(-10)), now: now) == "saved just now")
        #expect(SaveStatusText.text(for: .failed("x"), now: now) == "not saved, see Activity")
    }

    @Test func olderSaveShowsARelativeTime() {
        let text = SaveStatusText.text(for: .saved(now.addingTimeInterval(-600)), now: now)

        #expect(text?.hasPrefix("saved ") == true)
        #expect(text != "saved just now")
    }
}
