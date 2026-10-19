import Foundation

package enum PlanPolicy {
    package static let heading = "Plan"

    private static let checkbox = try! NSRegularExpression(pattern: #"^(\s*[-*+]\s+\[)([ xX])(\].*)$"#)

    package static func items(in body: String) -> [PlanItem] {
        lines(in: body).map(\.item)
    }

    package static func setting(_ wanted: String, done: Bool, in body: String) throws -> String {
        let found = lines(in: body)
        let key = wanted.trimmingCharacters(in: .whitespaces)
        let matches = Int(key).map { number in found.filter { $0.item.number == number } }
            ?? found.filter { $0.item.text.localizedCaseInsensitiveContains(key) }
        guard let match = matches.first else { throw AgentError.noPlanItem(key, steps: found.map(\.item.label)) }
        guard matches.count == 1 else { throw AgentError.planItemNotUnique(key, count: matches.count) }
        var all = body.components(separatedBy: "\n")
        let line = all[match.index] as NSString
        guard let result = checkbox.firstMatch(in: line as String, range: NSRange(location: 0, length: line.length)) else { return body }
        all[match.index] = line.substring(with: result.range(at: 1)) + (done ? "x" : " ") + line.substring(with: result.range(at: 3))
        return all.joined(separator: "\n")
    }

    private static func lines(in body: String) -> [(index: Int, item: PlanItem)] {
        guard let bounds = NoteSectionPolicy.bounds(of: heading, in: body) else { return [] }
        let all = body.components(separatedBy: "\n")
        var found: [(index: Int, item: PlanItem)] = []
        for index in bounds {
            let line = all[index] as NSString
            guard let result = checkbox.firstMatch(in: all[index], range: NSRange(location: 0, length: line.length)) else { continue }
            let text = String(line.substring(with: result.range(at: 3)).dropFirst()).trimmingCharacters(in: .whitespaces)
            guard text.isEmpty == false else { continue }
            let isDone = line.substring(with: result.range(at: 2)) != " "
            found.append((index, PlanItem(number: found.count + 1, text: text, isDone: isDone)))
        }
        return found
    }
}
