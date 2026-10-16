import Foundation
import SlateDomain
import SlateMocks

extension PresentationAssembly {

    static func preview() -> PresentationAssembly {
        let ports = Ports.mock()
        let assembly = PresentationAssembly(ports: ports, useCases: UseCases(ports: ports), activity: ActivityLog(), vaultRoot: URL(fileURLWithPath: NSTemporaryDirectory()))
        assembly.vault.config = MockVault.config
        assembly.noteList.summaries = MockVault.notes
        if let document = MockVault.documents.first {
            assembly.navigator.selectedNote = document.id
            assembly.editor.show(document)
        }
        return assembly
    }
}
