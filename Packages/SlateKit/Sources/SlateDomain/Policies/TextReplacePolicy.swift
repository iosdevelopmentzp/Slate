import Foundation

package enum TextReplacePolicy {
    package static func replacing(_ old: String, with new: String, in body: String) throws -> String {
        guard old.isEmpty == false else { throw AgentError.missingArgument("old") }
        let count = body.components(separatedBy: old).count - 1
        guard count > 0 else { throw AgentError.textNotFound }
        guard count == 1 else { throw AgentError.textNotUnique(count) }
        return body.replacingOccurrences(of: old, with: new)
    }
}
