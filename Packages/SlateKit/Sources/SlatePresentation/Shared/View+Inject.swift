import SwiftUI
import SlateUI

extension View {

    func inject(_ assembly: PresentationAssembly) -> some View {
        self
            .environment(assembly.navigator)
            .environment(assembly.activity)
            .environment(assembly.toaster)
            .environment(assembly.layout)
            .environment(assembly.vault)
            .environment(assembly.noteList)
            .environment(assembly.editor)
            .environment(assembly.search)
            .environment(assembly.settings)
            .environment(assembly.capture)
            .environment(assembly.daily)
            .environment(assembly.history)
            .environment(assembly.todos)
            .environment(assembly.palette)
            .environment(\.hintCenter, assembly.hints)
            .environment(\.copyToPasteboard, { value, label in assembly.toaster.copy(value, label: label) })
    }
}
