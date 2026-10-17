import Foundation
import SlateDomain

struct MockAgentChangeLog: AgentChangeLog {
    func record(_ change: AgentChange) async throws {}

    func changes(after date: Date) async throws -> [AgentChange] {
        []
    }
}
