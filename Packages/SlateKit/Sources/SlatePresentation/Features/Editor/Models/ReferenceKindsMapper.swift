import Foundation
import SlateDomain
import SlateEditor

enum ReferenceKindsMapper {
    static func kinds(project: ProjectInfo?, ticketAddress: String) -> TextReference.Kinds {
        var kinds: TextReference.Kinds = []
        if ticketAddress.trimmingCharacters(in: .whitespaces).isEmpty == false { kinds.insert(.tickets) }
        if project?.repositories.isEmpty == false { kinds.insert(.files) }
        if let remote = project?.remote, ReferenceLinkPolicy.webAddress(remote: remote) != nil {
            kinds.formUnion([.mergeRequests, .commits])
        }
        return kinds
    }
}
