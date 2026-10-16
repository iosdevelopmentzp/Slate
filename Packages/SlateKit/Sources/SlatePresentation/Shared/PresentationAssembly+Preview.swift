import Foundation
import SlateDomain
import SlateMocks

extension PresentationAssembly {

    static func preview() -> PresentationAssembly {
        let ports = Ports.mock()
        let assembly = PresentationAssembly(ports: ports, useCases: UseCases(ports: ports), activity: ActivityLog())
        assembly.noteList.spaces = MockVault.spaces
        assembly.noteList.summaries = MockVault.notes
        assembly.navigator.selectedNote = MockVault.taskNotes.first?.id
        return assembly
    }
}
