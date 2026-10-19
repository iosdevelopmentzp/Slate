import AppKit

final class RichTextController: NSObject {
    let textView: RichTextView
    let scrollView: NSScrollView
    let styler: RichTextStyler
    var handlers = EditorHandlers()
    var onMarkdownChange: (String) -> Void = { _ in }
    weak var commands: EditorCommands? {
        didSet {
            commands?.controller = self
            updateState()
        }
    }
    private(set) var markdown = ""
    var emptyTailBlock = BlockAttributes()
    var isEditingInternally = false
    var nextGroup = 1_000_000
    var activeLinkPopover: LinkPopover?
    var pendingInline: InlineStyle?
    weak var activeTable: TableBlockView?
    var imageTarget: TableImageTarget?
    let imageButton = ImageSaveButton()
    let imageHandle = ImageResizeHandle()
    let linkBar = LinkBar()
    let multiCaret = MultiCaret()
    lazy var findClient = NoteFindClient(controller: self)
    lazy var finder: NSTextFinder = {
        let finder = NSTextFinder()
        finder.client = findClient
        finder.findBarContainer = scrollView
        finder.isIncrementalSearchingEnabled = true
        return finder
    }()

    private let undo = UndoManager()
    private var publishTask: Task<Void, Never>?
    static let immediatePublishLength = 12_000
    static let publishDelay: Duration = .milliseconds(250)
    private var pendingRange: NSRange?
    private var isStyling = false
    private var insertionToken: Int?
    private var focusToken: Int?
    private var lastWidth: CGFloat = 0

    init(configuration: EditorConfiguration) {
        styler = RichTextStyler(configuration: configuration)
        textView = RichTextView(usingTextLayoutManager: true)
        scrollView = NSScrollView()
        super.init()
        configureTextView()
        styler.loadImage = { [weak self] path in
            guard let self else { return nil }
            return loadImage(path)
        }
        styler.tableHost = self
        linkBar.onAction = { [weak self] action, range in
            guard let self else { return }
            performLinkAction(action, range: range)
        }
        imageButton.onSave = { [weak self] path in
            guard let self else { return }
            handlers.attachment(path, .saveToDownloads)
        }
        imageHandle.onResize = { [weak self] location, width in
            guard let self else { return }
            previewImageWidth(at: location, width: width)
        }
        imageHandle.onFinish = { [weak self] location, width in
            guard let self else { return }
            setImageWidth(at: location, width: Int(width))
        }
    }

    var storage: NSTextStorage {
        textView.textStorage ?? NSTextStorage()
    }

    var string: NSString {
        storage.string as NSString
    }

    private func configureTextView() {
        textView.controller = self
        textView.isRichText = true
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
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 0, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.usesFindBar = false
        textView.isIncrementalSearchingEnabled = true
        textView.delegate = self
        textView.textStorage?.delegate = self
        textView.textLayoutManager?.delegate = self
        textView.postsFrameChangedNotifications = true
        textView.setAccessibilityLabel("Note text")
        NotificationCenter.default.addObserver(self, selector: #selector(frameChanged), name: NSView.frameDidChangeNotification, object: textView)
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.documentView = textView
        textView.typingAttributes = styler.attributes(block: BlockAttributes(), inline: [], href: nil)
    }

    func setMarkdown(_ value: String) {
        guard value != markdown || storage.length == 0 && value.isEmpty == false else { return }
        activeTable?.endEditing(commit: false)
        imageTarget = nil
        linkBar.hide()
        publishTask?.cancel()
        publishTask = nil
        let text = MarkdownReader.read(value)
        restyle(text, range: NSRange(location: 0, length: text.length))
        isStyling = true
        storage.setAttributedString(text)
        isStyling = false
        markdown = value
        emptyTailBlock = BlockAttributes()
        undo.removeAllActions()
        pendingRange = nil
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        updateTypingAttributes()
        updateState()
    }

    func apply(configuration: EditorConfiguration) {
        guard styler.configuration != configuration else { return }
        styler.configuration = configuration
        styler.forgetImages()
        restyleAll()
    }

    func reloadImages() {
        styler.forgetImages()
        restyleAll()
        storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: storage.length)) { value, _, _ in
            (value as? TableAttachment)?.reloadPictures()
        }
    }

    func restyleAll() {
        guard storage.length > 0 else { return }
        isStyling = true
        storage.beginEditing()
        restyle(storage, range: NSRange(location: 0, length: storage.length))
        storage.endEditing()
        isStyling = false
        updateTypingAttributes()
    }

    func apply(insertion: EditorInsertion?) {
        guard let insertion, insertion.token != insertionToken else { return }
        insertionToken = insertion.token
        if let target = imageTarget {
            imageTarget = nil
            insertIntoCell(insertion.markdown, target: target)
            return
        }
        insertMarkdownBlocks(insertion.markdown)
    }

    func apply(focus: EditorFocusRequest?) {
        guard let focus, focus.token != focusToken else { return }
        focusToken = focus.token
        let location = focus.atStart ? 0 : firstMatch(of: focus.words) ?? storage.length
        Task { @MainActor [weak self] in
            guard let self else { return }
            textView.window?.makeFirstResponder(textView)
            textView.setSelectedRange(NSRange(location: min(location, storage.length), length: 0))
            textView.scrollRangeToVisible(NSRange(location: min(location, storage.length), length: 0))
        }
    }

    func focus() {
        textView.window?.makeFirstResponder(textView)
    }

    private func firstMatch(of words: [String]) -> Int? {
        let matches = words.filter { $0.isEmpty == false }.compactMap { word -> Int? in
            let found = string.range(of: word, options: [.caseInsensitive, .diacriticInsensitive])
            return found.location == NSNotFound ? nil : found.location
        }
        return matches.min()
    }

    func publish() {
        guard storage.length > Self.immediatePublishLength else {
            publishNow()
            return
        }
        publishTask?.cancel()
        publishTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.publishDelay)
            guard Task.isCancelled == false, let self else { return }
            publishNow()
        }
    }

    func flush() {
        activeTable?.commit()
        guard publishTask != nil else { return }
        publishNow()
    }

    func publishNow() {
        publishTask?.cancel()
        publishTask = nil
        let written = MarkdownWriter.write(storage)
        guard written != markdown else { return }
        markdown = written
        onMarkdownChange(written)
    }

    func noteEdit(_ range: NSRange) {
        pendingRange = pendingRange.map { NSUnionRange($0, range) } ?? range
    }

    func textChanged() {
        if let range = pendingRange, textView.hasMarkedText() == false {
            pendingRange = nil
            let clamped = NSIntersectionRange(range, NSRange(location: 0, length: storage.length))
            isStyling = true
            storage.beginEditing()
            restyle(storage, range: NSRange(location: clamped.location, length: clamped.length))
            storage.endEditing()
            isStyling = false
        }
        publish()
        updateTypingAttributes()
        updateState()
    }

    func storageEdited(_ mask: NSTextStorageEditActions, range: NSRange, delta: Int) {
        guard isStyling == false else { return }
        if multiCaret.isApplying == false { dropExtraCarets() }
        if var pending = pendingRange {
            if delta != 0, pending.location > range.location {
                pending.location = max(range.location, pending.location + delta)
            } else if delta != 0, NSMaxRange(pending) > range.location {
                pending.length = max(0, pending.length + delta)
            }
            pendingRange = NSUnionRange(pending, range)
        } else {
            pendingRange = range
        }
    }

    func restyle(_ text: NSMutableAttributedString, range: NSRange) {
        guard text.length > 0 else { return }
        let string = text.string as NSString
        let start = min(range.location, text.length - 1)
        var lower = string.paragraphRange(for: NSRange(location: start, length: 0)).location
        while lower > 0 {
            let previous = string.paragraphRange(for: NSRange(location: lower - 1, length: 0))
            guard BlockAttributes(text.attributes(at: previous.location, effectiveRange: nil)).kind.isList else { break }
            lower = previous.location
        }
        var upper = NSMaxRange(string.paragraphRange(for: NSRange(location: min(NSMaxRange(range), text.length - 1), length: 0)))
        while upper < text.length {
            let next = string.paragraphRange(for: NSRange(location: upper, length: 0))
            guard BlockAttributes(text.attributes(at: next.location, effectiveRange: nil)).kind.isList else { break }
            upper = NSMaxRange(next)
        }
        var counters: [Int?] = []
        var location = lower
        while location < upper {
            let paragraph = string.paragraphRange(for: NSRange(location: location, length: 0))
            let block = BlockAttributes(text.attributes(at: paragraph.location, effectiveRange: nil))
            var number: Int?
            if block.kind.isList {
                let level = min(block.indent, counters.count)
                counters = Array(counters.prefix(level + 1))
                while counters.count < level + 1 { counters.append(nil) }
                if block.kind == .numbered {
                    let next = (counters[level] ?? 0) + 1
                    counters[level] = next
                    number = next
                } else {
                    counters[level] = nil
                }
            } else {
                counters = []
            }
            normalizeBlock(text, paragraph: paragraph, block: block)
            styler.style(text, paragraph: paragraph, number: number)
            location = NSMaxRange(paragraph)
        }
    }

    private func normalizeBlock(_ text: NSMutableAttributedString, paragraph: NSRange, block: BlockAttributes) {
        guard paragraph.length > 1 else { return }
        var uniform = true
        text.enumerateAttributes(in: paragraph) { attributes, _, stop in
            if BlockAttributes(attributes) != block {
                uniform = false
                stop.pointee = true
            }
        }
        guard uniform == false else { return }
        for key in NSAttributedString.Key.blockKeys {
            text.removeAttribute(key, range: paragraph)
        }
        text.addAttributes(block.attributes, range: paragraph)
    }

    func paragraphRange(at location: Int) -> NSRange {
        string.paragraphRange(for: NSRange(location: min(location, string.length), length: 0))
    }

    func contentRange(of paragraph: NSRange) -> NSRange {
        let end = NSMaxRange(paragraph)
        if end > paragraph.location, string.character(at: end - 1) == 0x0A {
            return NSRange(location: paragraph.location, length: paragraph.length - 1)
        }
        return paragraph
    }

    func isEmptyTail(_ location: Int) -> Bool {
        location >= storage.length && (storage.length == 0 || string.character(at: storage.length - 1) == 0x0A)
    }

    func block(at location: Int) -> BlockAttributes {
        if isEmptyTail(location) { return emptyTailBlock }
        let paragraph = paragraphRange(at: location)
        return BlockAttributes(storage.attributes(at: min(paragraph.location, storage.length - 1), effectiveRange: nil))
    }

    var currentBlock: BlockAttributes {
        block(at: textView.selectedRange().location)
    }

    func updateTypingAttributes() {
        let selection = textView.selectedRange()
        let block = block(at: selection.location)
        var inline: InlineStyle = []
        var href: String?
        if selection.location > 0, storage.length > 0, isEmptyTail(selection.location) == false {
            let index = min(selection.location - 1, storage.length - 1)
            if string.character(at: index) != 0x0A {
                let attributes = storage.attributes(at: index, effectiveRange: nil)
                inline = InlineStyle(rawValue: attributes[.slateInline] as? Int ?? 0)
                href = nil
            }
        }
        if let pendingInline {
            inline = pendingInline
        }
        textView.typingAttributes = styler.attributes(block: block.kind.isAttachment ? BlockAttributes() : block, inline: inline, href: href)
    }

    func updateState() {
        guard let commands else { return }
        let selection = textView.selectedRange()
        let block = block(at: selection.location)
        var inline = InlineStyle(rawValue: textView.typingAttributes[.slateInline] as? Int ?? 0)
        var isLink = false
        if selection.length > 0 {
            inline = [.bold, .italic, .strikethrough, .code]
            isLink = true
            storage.enumerateAttributes(in: selection) { attributes, range, _ in
                let text = string.substring(with: range)
                guard text.allSatisfy({ $0.isWhitespace || $0 == RichText.lineBreak }) == false else { return }
                inline.formIntersection(InlineStyle(rawValue: attributes[.slateInline] as? Int ?? 0))
                if attributes[.slateHref] == nil { isLink = false }
            }
        } else if selection.location > 0, selection.location <= storage.length, storage.length > 0 {
            isLink = storage.attribute(.slateHref, at: min(selection.location, storage.length - 1), effectiveRange: nil) != nil
        }
        let state = EditorStyleState(kind: block.kind, inline: inline, isLink: isLink, canFormatText: block.kind.keepsLineBreaks == false && block.kind.isAttachment == false, isInCell: activeTable?.editing != nil)
        if commands.state != state { commands.state = state }
    }

    @objc private func frameChanged() {
        let width = textView.textContainer?.size.width ?? 0
        guard abs(width - lastWidth) > 0.5 else { return }
        lastWidth = width
        refreshCaretOverlay()
        guard let textLayout = textView.textLayoutManager else { return }
        var hasAttachments = false
        storage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: storage.length)) { value, _, stop in
            if value != nil {
                hasAttachments = true
                stop.pointee = true
            }
        }
        guard hasAttachments else { return }
        textLayout.invalidateLayout(for: textLayout.documentRange)
    }

    private func loadImage(_ path: String) -> NSImage? {
        let decoded = path.removingPercentEncoding ?? path
        guard let url = handlers.resolveImage(decoded) else { return nil }
        return NSImage(contentsOf: url)
    }

    func makeGroup() -> Int {
        nextGroup += 1
        return nextGroup
    }

    var undoManager: UndoManager {
        undo
    }

    func undoEdit() {
        guard undo.canUndo else { return }
        undo.undo()
        textChanged()
    }

    func redoEdit() {
        guard undo.canRedo else { return }
        undo.redo()
        textChanged()
    }

    func handleInsertion(token: Int) {
        insertionToken = token
    }
}
