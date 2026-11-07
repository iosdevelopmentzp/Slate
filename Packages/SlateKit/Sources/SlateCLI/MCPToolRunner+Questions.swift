import Foundation
import SlateDomain

extension MCPToolRunner {
    func listQuestions(_ arguments: MCPArguments) async throws -> String {
        var paths: [VaultPath]
        if arguments.string("id") != nil || arguments.string("path") != nil {
            paths = [try await notePath(arguments)]
        } else if let raw = arguments.string("folder") {
            let folder = try await existingFolder(raw)
            paths = try await ports.index.summaries(space: nil).filter { folder.contains($0.path) }.map(\.path)
        } else {
            throw AgentError.missingArgument("id or folder")
        }
        paths.sort { $0.rawValue < $1.rawValue }
        var questions: [[String: Any]] = []
        for path in paths {
            guard let document = try? await document(at: path) else { continue }
            for question in QuestionPolicy.open(in: document.body) {
                var object: [String: Any] = [
                    "id": document.id.rawValue,
                    "path": path.rawValue,
                    "note": document.title,
                    "number": question.number,
                    "question": question.text,
                    "line": question.line,
                ]
                if question.title.isEmpty == false { object["title"] = question.title }
                questions.append(object)
            }
        }
        return json(questions)
    }

    func answerQuestion(_ arguments: MCPArguments) async throws -> String {
        let saved = try await rewrite("answer_question", arguments, change: try questionChange(arguments))
        var answer: [String: Any] = ["id": saved.id.rawValue, "path": saved.path.rawValue, "hash": saved.hash.rawValue]
        answer["open"] = QuestionPolicy.open(in: saved.body).count
        return json(answer)
    }

    func questionChange(_ arguments: MCPArguments) throws -> (String) throws -> String {
        guard arguments.values["number"] != nil else { throw AgentError.missingArgument("number") }
        let number = arguments.int("number", default: 1, maximum: 10_000)
        let answer = try arguments.required("answer")
        return { try QuestionPolicy.answering(number, with: answer, in: $0) }
    }
}
