import AppKit
import SwiftUI

package struct RichTextEditorView: NSViewRepresentable {
    package static let sideMargin: CGFloat = 16

    @Binding private var markdown: String
    private let configuration: EditorConfiguration
    private let commands: EditorCommands
    private let focus: EditorFocusRequest?
    private let insertion: EditorInsertion?
    private let handlers: EditorHandlers
    private let collapsedSections: [String]

    package init(
        markdown: Binding<String>,
        configuration: EditorConfiguration,
        commands: EditorCommands,
        focus: EditorFocusRequest? = nil,
        insertion: EditorInsertion? = nil,
        handlers: EditorHandlers = EditorHandlers(),
        collapsedSections: [String] = []
    ) {
        _markdown = markdown
        self.configuration = configuration
        self.commands = commands
        self.focus = focus
        self.insertion = insertion
        self.handlers = handlers
        self.collapsedSections = collapsedSections
    }

    package func makeCoordinator() -> Coordinator {
        Coordinator(controller: RichTextController(configuration: configuration))
    }

    package func makeNSView(context: Context) -> NSScrollView {
        let controller = context.coordinator.controller
        controller.handlers = handlers
        controller.commands = commands
        controller.onMarkdownChange = { [weak coordinator = context.coordinator] value in
            guard let coordinator else { return }
            coordinator.markdown?.wrappedValue = value
        }
        context.coordinator.markdown = $markdown
        controller.setMarkdown(markdown)
        controller.apply(collapsedSections: collapsedSections)
        return controller.scrollView
    }

    package func updateNSView(_ view: NSScrollView, context: Context) {
        let controller = context.coordinator.controller
        context.coordinator.markdown = $markdown
        controller.handlers = handlers
        if controller.commands !== commands { controller.commands = commands }
        controller.apply(configuration: configuration)
        controller.setMarkdown(markdown)
        controller.apply(collapsedSections: collapsedSections)
        controller.apply(insertion: insertion)
        controller.apply(focus: focus)
    }

    package final class Coordinator {
        let controller: RichTextController
        var markdown: Binding<String>?

        init(controller: RichTextController) {
            self.controller = controller
        }
    }
}
