import Foundation

package protocol RepositoryInspecting: Sendable {
    func inspect(_ directory: URL) async -> RepositoryInfo?
}
