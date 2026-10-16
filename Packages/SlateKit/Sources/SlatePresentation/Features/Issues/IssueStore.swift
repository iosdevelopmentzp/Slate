import Foundation
import Observation
import SlateDomain

@MainActor
@Observable
final class IssueStore {
    private(set) var details: [String: IssueDetails] = [:]
    private(set) var hasToken = false

    @ObservationIgnored private let tracker: any IssueTrackerClient
    @ObservationIgnored private let secrets: any SecretStore
    @ObservationIgnored private var loading: Set<String> = []
    @ObservationIgnored private var failed: Set<String> = []

    init(tracker: any IssueTrackerClient, secrets: any SecretStore) {
        self.tracker = tracker
        self.secrets = secrets
    }

    func refreshToken() async {
        hasToken = (await secrets.secret(for: TrackerSettings.tokenKey)).map { $0.isEmpty == false } ?? false
    }

    func load(_ key: String) async {
        guard hasToken, details[key] == nil, loading.contains(key) == false, failed.contains(key) == false else { return }
        loading.insert(key)
        defer { loading.remove(key) }
        do {
            details[key] = try await tracker.issue(key)
        } catch {
            failed.insert(key)
        }
    }

    func saveToken(_ token: String) async throws {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            try await secrets.removeSecret(for: TrackerSettings.tokenKey)
        } else {
            try await secrets.setSecret(trimmed, for: TrackerSettings.tokenKey)
        }
        details.removeAll()
        failed.removeAll()
        await refreshToken()
    }

    func test() async -> String {
        do {
            return "Connected as \(try await tracker.currentUser())."
        } catch {
            return error.localizedDescription
        }
    }
}
