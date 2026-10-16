import Testing
@testable import SlateData

@Suite struct IndexedNoteBuilderTests {
    @Test func countsHeadingsOutsideCodeFences() {
        let body = """
        # Title

        ## Section

        ```
        # not a heading
        ```
        """

        #expect(IndexedNoteBuilder().headingCount(in: body) == 2)
    }
}
