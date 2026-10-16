import SwiftUI
import SlateUI

extension View {

    func inject(_ assembly: PresentationAssembly) -> some View {
        self
            .environment(assembly.navigator)
            .environment(assembly.activity)
            .environment(assembly.toaster)
            .environment(assembly.layout)
            .environment(assembly.noteList)
            .environment(\.hintCenter, assembly.hints)
            .environment(\.copyToPasteboard, { value, label in assembly.toaster.copy(value, label: label) })
    }
}
