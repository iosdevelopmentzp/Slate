import Foundation
import SlateDomain

struct MockWorkspace: WorkspaceOpening {
    func open(_ url: URL) async {}

    func reveal(_ url: URL) async {}

    func quickLook(_ url: URL) async {}
}
