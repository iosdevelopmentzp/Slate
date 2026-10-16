import Foundation
import Testing
@testable import SlateDomain

@Suite struct TodoLinePolicyTests {
    @Test func parsesOpenAndDoneItems() {
        #expect(TodoLinePolicy.parse("- [ ] Break the cycle") == TodoLinePolicy.Parsed(text: "Break the cycle", isDone: false))
        #expect(TodoLinePolicy.parse("  2. [X] Done") == TodoLinePolicy.Parsed(text: "Done", isDone: true))
        #expect(TodoLinePolicy.parse("> - [ ] quoted")?.isDone == false)
        #expect(TodoLinePolicy.parse("- plain") == nil)
        #expect(TodoLinePolicy.parse("- [ ]")?.text == "")
    }

    @Test func toggleFlipsTheMark() {
        #expect(TodoLinePolicy.toggle("- [ ] a") == "- [x] a")
        #expect(TodoLinePolicy.toggle("- [x] a") == "- [ ] a")
        #expect(TodoLinePolicy.toggle("text") == nil)
    }
}
