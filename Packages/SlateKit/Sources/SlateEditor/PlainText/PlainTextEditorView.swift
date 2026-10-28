import AppKit
import SwiftUI

package struct PlainTextEditorView: NSViewRepresentable {
    @Binding private var text: String
    private let textSize: CGFloat
    private let resetToken: Int

    package init(text: Binding<String>, textSize: CGFloat, resetToken: Int) {
        _text = text
        self.textSize = textSize
        self.resetToken = resetToken
    }

    package func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    package func makeNSView(context: Context) -> NSScrollView {
        let textView = PlainTextView(usingTextLayoutManager: true)
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFontPanel = false
        textView.usesRuler = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.drawsBackground = false
        textView.textColor = .textColor
        textView.textContainerInset = NSSize(width: 16, height: 12)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.setAccessibilityLabel("File text")
        textView.delegate = context.coordinator
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.text = $text
        apply(to: textView, coordinator: context.coordinator)
        return scrollView
    }

    package func updateNSView(_ view: NSScrollView, context: Context) {
        context.coordinator.text = $text
        guard let textView = context.coordinator.textView else { return }
        apply(to: textView, coordinator: context.coordinator)
    }

    private func apply(to textView: NSTextView, coordinator: Coordinator) {
        let font = NSFont.monospacedSystemFont(ofSize: textSize, weight: .regular)
        if textView.font != font {
            textView.font = font
            textView.typingAttributes[.font] = font
        }
        guard textView.string != text || coordinator.resetToken != resetToken else { return }
        coordinator.resetToken = resetToken
        guard textView.string != text else { return }
        textView.string = text
        textView.font = font
        textView.undoManager?.removeAllActions()
    }

    package final class Coordinator: NSObject, NSTextViewDelegate {
        weak var textView: NSTextView?
        var text: Binding<String>?
        var resetToken: Int?

        package func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            text?.wrappedValue = textView.string
        }
    }
}
