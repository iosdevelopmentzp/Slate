import Foundation

enum ExportFormat: Equatable {
    case jira
    case slack

    var notice: String {
        switch self {
        case .jira: "Copied for Jira"
        case .slack: "Copied for Slack"
        }
    }
}
