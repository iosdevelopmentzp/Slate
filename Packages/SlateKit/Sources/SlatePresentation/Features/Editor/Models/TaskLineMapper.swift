import Foundation
import SlateDomain

enum TaskLineMapper {
    static func model(for header: NoteHeader, inProject: Bool) -> TaskLineModel? {
        guard inProject, header.type == NoteType.task.name else { return nil }
        let status = header.status.flatMap(NoteStatus.init(rawValue:)) ?? .todo
        return TaskLineModel(
            status: status,
            statusTag: TaskStatusMapper.tag(for: status),
            ticket: header.ticket.flatMap { $0.isEmpty ? nil : $0 },
            branch: header.branch.flatMap { $0.isEmpty ? nil : $0 }
        )
    }
}
