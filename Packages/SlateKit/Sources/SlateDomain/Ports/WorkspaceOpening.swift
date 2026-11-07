import Foundation

package protocol WorkspaceOpening: Sendable {
    func open(_ url: URL) async
    func reveal(_ url: URL) async
    func quickLook(_ url: URL) async
    func markUp(_ url: URL) async
    func openCode(_ path: String, line: Int?, in roots: [URL]) async -> Bool
}
