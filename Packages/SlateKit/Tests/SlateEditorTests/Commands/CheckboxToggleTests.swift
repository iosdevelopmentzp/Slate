import Foundation
import Testing
@testable import SlateEditor

@Suite struct CheckboxToggleTests {
    @Test func toggleChecksAndUnchecks() {
        #expect(CheckboxToggle.toggled("- [ ] a") == "- [x] a")
        #expect(CheckboxToggle.toggled("  * [X] a") == "  * [ ] a")
        #expect(CheckboxToggle.toggled("- a") == nil)
    }

    @Test func cycleGoesFromTextToOpenToCheckedToPlainItem() {
        #expect(CheckboxToggle.cycled("buy milk") == "- [ ] buy milk")
        #expect(CheckboxToggle.cycled("- [ ] buy milk") == "- [x] buy milk")
        #expect(CheckboxToggle.cycled("- [x] buy milk") == "- buy milk")
        #expect(CheckboxToggle.cycled("- buy milk") == "- [ ] buy milk")
    }

    @Test func cycleKeepsTheIndentAndOrderedMarker() {
        #expect(CheckboxToggle.cycled("  2. step") == "  2. [ ] step")
        #expect(CheckboxToggle.cycled("  text") == "  - [ ] text")
    }

    @Test func cycleOnAnEmptyLineStartsABox() {
        #expect(CheckboxToggle.cycled("") == "- [ ] ")
    }

    @Test func cycleKeepsAQuote() {
        #expect(CheckboxToggle.cycled("> - [ ] a") == "> - [x] a")
    }
}
