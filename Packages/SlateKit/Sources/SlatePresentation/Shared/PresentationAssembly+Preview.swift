import Foundation
import SlateDomain
import SlateMocks

extension PresentationAssembly {

    static func preview() -> PresentationAssembly {
        let ports = Ports.mock()
        let assembly = PresentationAssembly(ports: ports, useCases: UseCases(ports: ports), activity: ActivityLog())
        assembly.vault.config = MockVault.config
        assembly.vault.types = NoteType.builtIn
        assembly.noteList.summaries = MockVault.notes
        if let document = MockVault.documents.first(where: { $0.header.ticket == "ABC-123" }) {
            assembly.navigator.selectedNote = document.id
            assembly.editor.show(document)
        }
        return assembly
    }
}
