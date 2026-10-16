import Foundation

package struct ActionDefinition: Identifiable, Hashable, Sendable {
    package enum Condition: String, Hashable, Sendable {
        case always
        case task
        case hasBranch
        case hasTicket
        case hasMR
    }

    package enum Output: String, Hashable, Sendable {
        case activity
        case appendToNote
        case clipboard
    }

    package let id: String
    package var title: String
    package var icon: String?
    package var command: String
    package var condition: Condition
    package var output: Output

    package init(id: String, title: String, icon: String? = nil, command: String, condition: Condition = .always, output: Output = .activity) {
        self.id = id
        self.title = title
        self.icon = icon
        self.command = command
        self.condition = condition
        self.output = output
    }

    package func applies(to document: NoteDocument) -> Bool {
        let header = document.header
        switch condition {
        case .always: return true
        case .task: return document.type == NoteType.task.name
        case .hasBranch: return (header.branch ?? "").isEmpty == false
        case .hasTicket: return (header.ticket ?? "").isEmpty == false
        case .hasMR: return (header.mr ?? "").isEmpty == false
        }
    }
}
