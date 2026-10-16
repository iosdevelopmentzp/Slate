import AppKit

final class EditorController: NSObject {
    let textView: MarkdownTextView
    let scrollView: NSScrollView
    let container: EditorContainerView
    let styler: ParagraphStyler
    let copyButton = CodeCopyButton()
    private(set) var tracker = FenceTracker(text: "")
    var handlers = EditorHandlers() {
        didSet { images.removeAll() }
    }
    var onTextChange: (String) -> Void = { _ in }
    var pendingCode: (range: NSRange, language: String)?

    private let undo = UndoManager()
    private var images: [String: NSImage] = [:]
    private var pendingRestyle: NSRange?
    private var insertionToken: Int?

    var resolveImage: (String) -> URL? {
        get { handlers.resolveImage }
        set { handlers.resolveImage = newValue }
    }

    init(configuration: EditorConfiguration) {
        styler = ParagraphStyler(configuration: configuration)
        textView = MarkdownTextView(usingTextLayoutManager: true)
        scrollView = NSScrollView()
        container = EditorContainerView(scrollView: scrollView)
        super.init()
        configureTextView(configuration)
        styler.image = { [weak self] source in
            guard let self else { return nil }
            return image(for: source)
        }
        container.bar.onAccept = { [weak self] in
            guard let self else { return }
            acceptPasteSuggestion()
        }
        container.bar.onDismiss = { [weak self] in
            guard let self else { return }
            _ = dismissPasteSuggestion()
        }
        copyButton.target = self
        copyButton.action = #selector(copyCodeBlock)
        textView.addSubview(copyButton)
    }

    var text: String { textView.string }

    var nsText: NSString { textView.string as NSString }

    func setText(_ string: String) {
        guard textView.string != string else { return }
        textView.string = string
        undo.removeAllActions()
        _ = dismissPasteSuggestion()
        copyButton.isHidden = true
    }

    func apply(configuration: EditorConfiguration) {
        guard styler.configuration != configuration else { return }
        styler.configuration = configuration
        textView.font = configuration.proseFont
        restyleAll()
    }

    func apply(insertion: EditorInsertion?) {
        guard let insertion, insertion.token != insertionToken else { return }
        insertionToken = insertion.token
        insertBlock(insertion.markdown)
    }

    func restyleAll() {
        guard let storage = textView.textStorage, storage.length > 0 else { return }
        restyle(NSRange(location: 0, length: storage.length))
    }

    func updateWidth() {
        let width = textView.textContainer?.size.width ?? 600
        let available = max(width - 2 * (textView.textContainer?.lineFragmentPadding ?? 5), 40)
        guard abs(available - styler.availableWidth) > 1 else { return }
        styler.availableWidth = available
        restyleImages()
    }

    private func restyleImages() {
        for line in tracker.lines {
            guard case .image = line.kind else { continue }
            restyle(line.range)
        }
    }

    private func configureTextView(_ configuration: EditorConfiguration) {
        textView.controller = self
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFontPanel = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = false
        textView.drawsBackground = false
        textView.font = configuration.proseFont
        textView.textContainerInset = NSSize(width: 16, height: 12)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.delegate = self
        textView.textContentStorage?.delegate = self
        textView.textStorage?.delegate = self
        textView.textLayoutManager?.delegate = self
        textView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(frameChanged), name: NSView.frameDidChangeNotification, object: textView)
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.documentView = textView
    }

    @objc private func frameChanged() {
        updateWidth()
    }

    private func image(for source: String) -> NSImage? {
        if let cached = images[source] { return cached }
        let decoded = source.removingPercentEncoding ?? source
        guard let url = handlers.resolveImage(decoded), let image = NSImage(contentsOf: url) else { return nil }
        images[source] = image
        return image
    }

    func imageURL(for source: String) -> URL? {
        handlers.resolveImage(source.removingPercentEncoding ?? source)
    }

    func restyle(_ range: NSRange) {
        guard let storage = textView.textStorage, let contentStorage = textView.textContentStorage else { return }
        let clamped = NSIntersectionRange(range, NSRange(location: 0, length: storage.length))
        guard clamped.length > 0 else { return }
        contentStorage.performEditingTransaction {
            storage.edited(.editedAttributes, range: clamped, changeInLength: 0)
        }
    }

    fileprivate func flushRestyle() {
        guard let range = pendingRestyle else { return }
        pendingRestyle = nil
        restyle(range)
    }

    fileprivate func noteEdit(in storage: NSTextStorage, editedRange: NSRange, delta: Int) {
        let text = storage.string as NSString
        let changed = tracker.update(text: text, editedRange: editedRange, changeInLength: delta)
        if let pending = pendingCode, NSIntersectionRange(pending.range, editedRange).length == 0, editedRange.location != pending.range.upperBound {
            pendingCode = nil
            container.setBarVisible(false)
        }
        let edited = text.paragraphRange(for: editedRange)
        guard changed.upperBound > edited.upperBound else { return }
        let extra = NSRange(location: edited.upperBound, length: changed.upperBound - edited.upperBound)
        pendingRestyle = pendingRestyle.map { NSUnionRange($0, extra) } ?? extra
    }
}

extension EditorController: NSTextStorageDelegate {
    func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard editedMask.contains(.editedCharacters) else { return }
        noteEdit(in: textStorage, editedRange: editedRange, delta: delta)
    }

    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard pendingRestyle != nil else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            flushRestyle()
        }
    }
}

extension EditorController: NSTextContentStorageDelegate {
    func textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) -> NSTextParagraph? {
        guard let storage = textContentStorage.textStorage else { return nil }
        let source = (storage.string as NSString).substring(with: range)
        let line = tracker.state(at: range.location)
        return NSTextParagraph(attributedString: styler.style(source, line: line))
    }
}

extension EditorController: NSTextLayoutManagerDelegate {
    func textLayoutManager(_ textLayoutManager: NSTextLayoutManager, textLayoutFragmentFor location: any NSTextLocation, in textElement: NSTextElement) -> NSTextLayoutFragment {
        guard let paragraph = textElement as? NSTextParagraph,
              paragraph.attributedString.length > 0,
              let decoration = paragraph.attributedString.attribute(.slateDecoration, at: 0, effectiveRange: nil) as? LineDecoration else {
            return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
        }
        let fragment = MarkdownLayoutFragment(textElement: textElement, range: textElement.elementRange)
        fragment.decoration = decoration
        fragment.colors = styler.configuration.colors
        return fragment
    }
}

extension EditorController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        flushRestyle()
        onTextChange(textView.string)
    }

    func undoManager(for view: NSTextView) -> UndoManager? {
        undo
    }
}
