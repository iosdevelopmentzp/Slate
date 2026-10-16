import Foundation
import SlateDomain

enum JiraIssueParser {
    private struct IssueDTO: Decodable {
        struct Fields: Decodable {
            struct Status: Decodable { let name: String? }
            struct Person: Decodable { let displayName: String? }
            let summary: String?
            let status: Status?
            let assignee: Person?
        }

        let key: String
        let fields: Fields
    }

    private struct UserDTO: Decodable {
        let displayName: String?
    }

    static func issue(from data: Data) -> IssueDetails? {
        guard let dto = try? JSONDecoder().decode(IssueDTO.self, from: data) else { return nil }
        return IssueDetails(key: dto.key, summary: dto.fields.summary ?? "", status: dto.fields.status?.name, assignee: dto.fields.assignee?.displayName)
    }

    static func displayName(from data: Data) -> String? {
        (try? JSONDecoder().decode(UserDTO.self, from: data))?.displayName
    }
}
