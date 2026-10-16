import Testing
@testable import SlateDomain

@Suite struct NoteIDTests {
    @Test func generatedIDsAreLowercaseAndUnique() {
        let first = NoteID.generate()
        let second = NoteID.generate()

        #expect(first != second)
        #expect(first.rawValue == first.rawValue.lowercased())
        #expect(first.rawValue.count == 36)
    }
}
