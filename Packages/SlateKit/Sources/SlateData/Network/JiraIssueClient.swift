import Foundation
import SlateDomain

struct JiraIssueClient: IssueTrackerClient {
    let keyValues: any KeyValueStore
    let secrets: any SecretStore
    let session: URLSession

    func issue(_ key: String) async throws -> IssueDetails {
        let data = try await get("rest/api/3/issue/\(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)?fields=summary,status,assignee")
        guard let details = JiraIssueParser.issue(from: data) else { throw TrackerError.unreadable }
        return details
    }

    func currentUser() async throws -> String {
        let data = try await get("rest/api/3/myself")
        guard let name = JiraIssueParser.displayName(from: data) else { throw TrackerError.unreadable }
        return name
    }

    private func get(_ path: String) async throws -> Data {
        let settings = TrackerSettings.load(from: keyValues)
        var base = settings.trackerBaseURL.trimmingCharacters(in: .whitespaces)
        while base.hasSuffix("/") { base.removeLast() }
        guard base.isEmpty == false, settings.trackerEmail.isEmpty == false,
              let token = await secrets.secret(for: TrackerSettings.tokenKey), token.isEmpty == false,
              let url = URL(string: "\(base)/\(path)") else { throw TrackerError.notConfigured }
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.setValue("Basic " + Data("\(settings.trackerEmail):\(token)".utf8).base64EncodedString(), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else { throw TrackerError.rejected(code) }
        return data
    }
}
