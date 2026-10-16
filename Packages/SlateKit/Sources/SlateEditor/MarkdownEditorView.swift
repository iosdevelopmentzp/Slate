import AppKit
import SwiftUI

package struct MarkdownEditorView: NSViewRepresentable {
    @Binding private var text: String
    private let configuration: EditorConfiguration
    private let focus: EditorFocusRequest?
    private let insertion: EditorInsertion?
    private let handlers: EditorHandlers

    package init(
        text: Binding<String>,
        configuration: EditorConfiguration,
        focus: EditorFocusRequest? = nil,
        insertion: EditorInsertion? = nil,
        handlers: EditorHandlers = EditorHandlers()
    ) {
        _text = text
        self.configuration = configuration
        self.focus = focus
        self.insertion = insertion
        self.handlers = handlers
    }

    package func makeCoordinator() -> Coordinator {
        Coordinator(controller: EditorController(configuration: configuration))
    }

    package func makeNSView(context: Context) -> NSView {
        let coordinator = context.coordinator
        coordinator.text = $text
        coordinator.controller.handlers = handlers
        coordinator.controller.onTextChange = { [weak coordinator] string in
            guard let coordinator else { return }
            coordinator.text?.wrappedValue = string
        }
        coordinator.controller.setText(text)
        return coordinator.controller.container
    }

    package func updateNSView(_ view: NSView, context: Context) {
        let coordinator = context.coordinator
        let controller = coordinator.controller
        coordinator.text = $text
        controller.handlers = handlers
        controller.apply(configuration: configuration)
        controller.setText(text)
        controller.apply(insertion: insertion)
        guard let focus, focus.token != coordinator.focusToken else { return }
        coordinator.focusToken = focus.token
        let textView = controller.textView
        let length = (textView.string as NSString).length
        let caret = min(max(focus.caret ?? length, 0), length)
        Task { @MainActor in
            textView.window?.makeFirstResponder(textView)
            textView.setSelectedRange(NSRange(location: caret, length: 0))
            textView.scrollRangeToVisible(NSRange(location: caret, length: 0))
        }
    }

    package final class Coordinator: NSObject {
        let controller: EditorController
        var text: Binding<String>?
        var focusToken: Int?

        init(controller: EditorController) {
            self.controller = controller
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(didEndEditing), name: NSText.didEndEditingNotification, object: controller.textView)
        }

        @objc private func didEndEditing() {
            controller.handlers.didEndEditing()
        }
    }
}
