import Testing
@testable import SlateDomain

@Suite struct QuestionPolicyTests {
    private let body = """
    ## Plan

    > [!QUESTION] Cache
    > Why do we keep the cache?
    > For how long?

    ```
    > [!QUESTION] not a question in code
    ```

    > [!question]
    > Who owns the API?

    > [!ANSWER]
    > Done before.
    """

    @Test func openQuestionsAreNumberedInOrder() {
        let questions = QuestionPolicy.open(in: body)

        #expect(questions.map(\.number) == [1, 2])
        #expect(questions[0] == OpenQuestion(number: 1, title: "Cache", text: "Why do we keep the cache?\nFor how long?", line: 3))
        #expect(questions[1].text == "Who owns the API?")
        #expect(questions[1].title.isEmpty)
    }

    @Test func anAnswerGoesIntoTheCalloutAndClosesIt() throws {
        let answered = try QuestionPolicy.answering(2, with: "The platform team.\n\nSee the wiki.", in: body)

        #expect(answered.contains("> [!ANSWER]\n> Who owns the API?\n>\n> **Answer:** The platform team.\n>\n> See the wiki.\n\n> [!ANSWER]\n> Done before."))
        #expect(QuestionPolicy.open(in: answered).map(\.title) == ["Cache"])
    }

    @Test func aWrongNumberSaysHowManyAreOpen() {
        #expect(throws: AgentError.noQuestion(3, open: 2)) {
            try QuestionPolicy.answering(3, with: "x", in: body)
        }
    }

    @Test func anEmptyAnswerIsRefused() {
        #expect(throws: AgentError.missingArgument("answer")) {
            try QuestionPolicy.answering(1, with: "  ", in: body)
        }
    }
}
