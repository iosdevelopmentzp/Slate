import AppKit

nonisolated final class TableViewProvider: NSTextAttachmentViewProvider {
    override init(textAttachment: NSTextAttachment, parentView: NSView?, textLayoutManager: NSTextLayoutManager?, location: any NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)
        tracksTextAttachmentViewBounds = true
    }

    override func loadView() {
        nonisolated(unsafe) let table = textAttachment as? TableAttachment
        nonisolated(unsafe) var loaded: NSView?
        MainActor.assumeIsolated {
            loaded = table?.view()
        }
        guard let loaded else {
            super.loadView()
            return
        }
        view = loaded
    }

    override func attachmentBounds(for attributes: [NSAttributedString.Key: Any], location: any NSTextLocation, textContainer: NSTextContainer?, proposedLineFragment: CGRect, position: CGPoint) -> CGRect {
        guard let table = textAttachment as? TableAttachment else { return .zero }
        return table.bounds(in: textContainer, proposed: proposedLineFragment)
    }
}
