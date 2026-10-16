import SwiftUI
import SlateDomain
import SlateUI

struct NoteWindowView: View {
    @Environment(EditorStore.self) private var editor
    @Environment(Toaster.self) private var toaster

    var body: some View {
        EditorView()
            .overlay(alignment: .bottom) {
                if let toast = toaster.text {
                    ToastView(text: toast, actionTitle: toaster.actionTitle) {
                        toaster.performAction()
                    }
                    .padding(.bottom, 12)
                }
            }
            .frame(minWidth: 320, minHeight: 240)
            .background(Theme.surface)
    }
}

#Preview("Light") {
    NoteWindowView()
        .previewEnvironment()
        .frame(width: 420, height: 520)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    NoteWindowView()
        .previewEnvironment()
        .frame(width: 420, height: 520)
        .preferredColorScheme(.dark)
}
