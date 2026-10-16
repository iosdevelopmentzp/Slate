import SwiftUI
import SlateDomain

extension EnvironmentValues {
    @Entry var openNoteWindow: (NoteID, Bool) -> Void = { _, _ in }
}
