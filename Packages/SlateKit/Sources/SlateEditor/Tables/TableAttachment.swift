import AppKit
import UniformTypeIdentifiers

nonisolated final class TableAttachment: NSTextAttachment {
    private(set) var block: TableBlock
    private(set) var style: TableStyle
    private(set) var model: TableModel
    private var texts: [[NSAttributedString]] = []
    private var cachedLayout: (width: CGFloat, layout: TableLayout)?
    nonisolated(unsafe) weak var host: (any TableHost)?
    nonisolated(unsafe) private var cachedView: TableBlockView?
    static let fileType = UTType.tabSeparatedText.identifier
    private static let registered: Void = NSTextAttachment.registerViewProviderClass(TableViewProvider.self, forFileType: fileType)

    @MainActor
    init(block: TableBlock, style: TableStyle) {
        self.block = block
        self.style = style
        model = block.model
        _ = Self.registered
        super.init(data: Data([0x09]), ofType: Self.fileType)
        allowsTextAttachmentView = true
        rebuildTexts()
    }

    required init?(coder: NSCoder) {
        nil
    }

    @MainActor
    func update(block: TableBlock, style: TableStyle) {
        guard block != self.block || style != self.style else { return }
        self.block = block
        self.style = style
        model = block.model
        rebuildTexts()
        cachedView?.modelChanged()
    }

    @MainActor
    func setLiveModel(_ live: TableModel) {
        guard live != model else { return }
        model = live
        rebuildTexts()
    }

    func text(_ index: TableCellIndex) -> NSAttributedString {
        guard index.row < texts.count, index.column < texts[index.row].count else { return NSAttributedString() }
        return texts[index.row][index.column]
    }

    func layout(width available: CGFloat) -> TableLayout {
        if let cachedLayout, abs(cachedLayout.width - available) < 0.5 { return cachedLayout.layout }
        let layout = TableLayout.make(texts: texts, available: available - TableLayout.handle, lineHeight: style.lineHeight)
        cachedLayout = (available, layout)
        return layout
    }

    var lastWidth: CGFloat {
        cachedLayout?.width ?? 600
    }

    @MainActor
    private func rebuildTexts() {
        cachedLayout = nil
        texts = model.allRows.enumerated().map { row, cells in
            cells.enumerated().map { column, cell in
                let alignment = column < model.columns.count ? model.columns[column].alignment : .none
                let inline = TableCellText.inline(cell.markdown) ?? NSAttributedString(string: cell.markdown)
                return style.styled(inline, header: row == 0, alignment: alignment)
            }
        }
    }

    func bounds(in textContainer: NSTextContainer?, proposed: CGRect) -> CGRect {
        let padding = textContainer?.lineFragmentPadding ?? 5
        let available = (textContainer?.size.width ?? proposed.width) - padding * 2
        let size = layout(width: available).size
        return CGRect(x: 0, y: 0, width: size.width + TableLayout.handle, height: size.height + TableLayout.handle)
    }

    override func image(for bounds: CGRect, attributes: [NSAttributedString.Key: Any], location: any NSTextLocation, textContainer: NSTextContainer?) -> NSImage? {
        NSImage(size: bounds.size)
    }

    @MainActor
    func view() -> TableBlockView {
        if let cachedView { return cachedView }
        let created = TableBlockView(attachment: self)
        cachedView = created
        return created
    }

    var loadedView: TableBlockView? {
        cachedView
    }
}
