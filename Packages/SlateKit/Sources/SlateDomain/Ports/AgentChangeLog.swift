import Foundation

package protocol AgentChangeLog: Sendable {
    func record(_ change: AgentChange) async throws
    func changes(after date: Date) async throws -> [AgentChange]
}
