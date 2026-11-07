import Foundation
import SlateDomain
import SlateEditor

extension EditorStore {
    func openReference(_ reference: TextReference, project: ProjectInfo?, ticketAddress: String) async {
        switch reference {
        case .file(let path, let line):
            let roots = (project?.repositories ?? []).map { URL(fileURLWithPath: $0, isDirectory: true) }
            guard roots.isEmpty == false else {
                toaster.show("Link a repository to this project to open code files.")
                return
            }
            if await workspace.openCode(path, line: line, in: roots) == false {
                toaster.show("Slate did not find \(path) in the repository of this project.")
            }
        case .ticket(let key):
            guard let url = ReferenceLinkPolicy.ticketURL(key, base: ticketAddress) else { return }
            await workspace.open(url)
        case .mergeRequest(let number):
            guard let url = project?.remote.flatMap({ ReferenceLinkPolicy.mergeRequestURL(number, remote: $0) }) else { return }
            await workspace.open(url)
        case .commit(let hash):
            guard let url = project?.remote.flatMap({ ReferenceLinkPolicy.commitURL(hash, remote: $0) }) else { return }
            await workspace.open(url)
        }
    }
}
