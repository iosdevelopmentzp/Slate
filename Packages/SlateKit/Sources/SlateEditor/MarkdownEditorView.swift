import AppKit
import SwiftUI

package struct MarkdownEditorView: NSViewRepresentable {
    @Binding private var text: String
    private let configuration: EditorConfiguration
    private let focus: EditorFocusRequest?
    private let handlers: EditorHandlers

    package init(text: Binding<String>, configuration: EditorConfiguration, focus: EditorFocusRequest? = nil, handlers: EditorHandlers = EditorHandlers()) {
        _text = text
        self.configuration = configuration
        self.focus = focus
        self.handlers = handlers
    }

    package func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, handlers: handlers)
    }

    package func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView(usingTextLayoutManager: true)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFontPanel = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.drawsBackground = false
        textView.font = configuration.proseFont
        textView.textContainerInset = NSSize(width: 16, height: 12)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.delegate = context.coordinator
        textView.string = text

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.documentView = textView
        return scrollView
    }

    package func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.text = $text
        context.coordinator.handlers = handlers
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        guard let focus, focus.token != context.coordinator.focusToken else { return }
        context.coordinator.focusToken = focus.token
        let length = (textView.string as NSString).length
        let caret = min(max(focus.caret ?? length, 0), length)
        Task { @MainActor in
            textView.window?.makeFirstResponder(textView)
            textView.setSelectedRange(NSRange(location: caret, length: 0))
            textView.scrollRangeToVisible(NSRange(location: caret, length: 0))
        }
    }

    package final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var handlers: EditorHandlers
        var focusToken: Int?

        init(text: Binding<String>, handlers: EditorHandlers) {
            self.text = text
            self.handlers = handlers
        }

        package func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }

        package func textDidEndEditing(_ notification: Notification) {
            handlers.didEndEditing()
        }
    }
}
