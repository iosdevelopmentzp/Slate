import Foundation

package protocol SearchIndex: Sendable {
    func summaries(space: SpaceName?) async throws -> [NoteSummary]
}
