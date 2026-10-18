import Foundation

package enum TaskError: LocalizedError, Hashable, Sendable {
    case notAProject(String)
    case notATask(String)

    package var errorDescription: String? {
        switch self {
        case .notAProject(let name):
            "\(name) is not a project. Make it a project first, or choose another one."
        case .notATask(let name):
            "\(name) is not a task note. A task note has type: task in its header."
        }
    }
}
