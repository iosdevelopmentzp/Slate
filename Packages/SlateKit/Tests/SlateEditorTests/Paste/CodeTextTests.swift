import Testing
@testable import SlateEditor

@Suite struct CodeTextTests {
    @Test func oneLineJSONIsIndented() throws {
        let block = try #require(CodeText.block(from: #"{"data":{"id":"a,b","keys":[1,{}],"empty":[]}}"#))

        #expect(block.language == "json")
        #expect(block.code == """
        {
          "data": {
            "id": "a,b",
            "keys": [
              1,
              {}
            ],
            "empty": []
          }
        }
        """)
    }

    @Test func indentedJSONKeepsItsLines() throws {
        let text = "\n{\n  \"key\" : \"title\",\n  \"type\" : \"translateKey\"\n}\n\n"

        let block = try #require(CodeText.block(from: text))

        #expect(block.code == "{\n  \"key\" : \"title\",\n  \"type\" : \"translateKey\"\n}")
        #expect(block.language == "json")
    }

    @Test func codeLinesAreCode() throws {
        let text = "func load() {\n    let value = 1\n    print(value)\n}"

        let block = try #require(CodeText.block(from: text))

        #expect(block.code == text)
        #expect(block.language == nil)
    }

    @Test func proseStaysText() {
        #expect(CodeText.block(from: "Buy milk.\nCall Anna about the trip.\nRead the report (part 2).") == nil)
        #expect(CodeText.block(from: "one line with {braces}") == nil)
        #expect(CodeText.block(from: "{not json") == nil)
    }
}
