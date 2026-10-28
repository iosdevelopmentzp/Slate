import Foundation

package enum TaskError: LocalizedError, Hashable, Sendable {
    case notAProject(String)
    case notATask(String)
    case outsideProject(String, project: String)

    package var errorDescription: String? {
        switch self {
        case .notAProject(let name):
            "\(name) is not a project. Make it a project first, or choose another one."
        case .notATask(let name):
            "\(name) is not a task note. A task note has type: task in its header."
        case .outsideProject(let folder, let project):
            "\(folder) is not inside the project \(project). Use a folder of the project, like \(project)/Features."
        }
    }
}
