import Foundation
import Testing
@testable import SlateData

@Suite struct FTSMatchBuilderTests {
    @Test func wordsBecomePrefixQueries() {
        #expect(FTSMatchBuilder.match(terms: ["retain", "cycle"], phrases: []) == #""retain"* "cycle"*"#)
    }

    @Test func phrasesStayExact() {
        #expect(FTSMatchBuilder.match(terms: [], phrases: ["audio engine"]) == #""audio engine""#)
    }

    @Test func quotesAreDoubled() {
        #expect(FTSMatchBuilder.match(terms: [#"say"hi"#], phrases: []) == #""say""hi"*"#)
    }

    @Test func punctuationOnlyWordsAreDropped() {
        #expect(FTSMatchBuilder.match(terms: ["(", ":", "-", "ABC-123"], phrases: ["..."]) == #""ABC-123"*"#)
    }
}
