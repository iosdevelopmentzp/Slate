import AppKit

extension EditorController {
    func completionContext() -> CompletionContext? {
        let selection = textView.selectedRange()
        guard selection.length == 0, tracker.state(at: selection.location).kind.isCode == false else { return nil }
        return CompletionContext.at(selection.location, in: nsText)
    }

    func completionText(_ word: String, range: NSRange, movement: Int, isFinal: Bool) -> String {
        guard isFinal, movement != NSTextMovement.cancel.rawValue, let context = completionContext(), context.kind == .note else { return word }
        let after = range.upperBound
        let closed = after + 2 <= nsText.length && nsText.substring(with: NSRange(location: after, length: 2)) == "]]"
        return closed ? word : word + "]]"
    }

    func startCompletionIfNeeded() {
        guard let context = completionContext() else { return }
        let starts = context.kind == .note ? context.range.length == 0 : context.range.length == 1
        guard starts else { return }
        let textView = textView
        Task { @MainActor in
            textView.complete(nil)
        }
    }
}
