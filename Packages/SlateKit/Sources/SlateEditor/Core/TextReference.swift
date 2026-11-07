import Foundation

nonisolated package enum TextReference: Equatable, Hashable, Sendable {
    case file(path: String, line: Int?)
    case ticket(String)
    case mergeRequest(Int)
    case commit(String)

    package struct Kinds: OptionSet, Hashable, Sendable {
        package let rawValue: Int

        package init(rawValue: Int) {
            self.rawValue = rawValue
        }

        package static let files = Kinds(rawValue: 1)
        package static let tickets = Kinds(rawValue: 2)
        package static let mergeRequests = Kinds(rawValue: 4)
        package static let commits = Kinds(rawValue: 8)
    }

    var kind: Kinds {
        switch self {
        case .file: .files
        case .ticket: .tickets
        case .mergeRequest: .mergeRequests
        case .commit: .commits
        }
    }

    var raw: String {
        switch self {
        case .file(let path, let line): "file:" + path + (line.map { ":\($0)" } ?? "")
        case .ticket(let key): "ticket:" + key
        case .mergeRequest(let number): "mr:\(number)"
        case .commit(let hash): "commit:" + hash
        }
    }

    init?(raw: String) {
        let parts = raw.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        switch parts[0] {
        case "file":
            let pieces = parts[1].split(separator: ":").map(String.init)
            self = .file(path: pieces[0], line: pieces.count > 1 ? Int(pieces[1]) : nil)
        case "ticket": self = .ticket(parts[1])
        case "mr":
            guard let number = Int(parts[1]) else { return nil }
            self = .mergeRequest(number)
        case "commit": self = .commit(parts[1])
        default: return nil
        }
    }
}
