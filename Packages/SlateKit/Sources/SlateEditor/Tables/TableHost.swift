import AppKit

protocol TableHost: AnyObject {
    func tableDidChange(_ attachment: TableAttachment, model: TableModel, before: TableModel?)
    func tableNeedsLayout(_ attachment: TableAttachment)
    func leaveTable(_ attachment: TableAttachment, after: Bool)
    func deleteTable(_ attachment: TableAttachment)
    func tableBeganEditing(_ view: TableBlockView)
    func tableEndedEditing(_ view: TableBlockView)
    func undoInDocument(redo: Bool)
    func pasteIntoCell(_ view: TableBlockView)
    func dropIntoCell(_ dragging: any NSDraggingInfo, target: TableImageTarget) -> Bool
    func convertTableToText(_ attachment: TableAttachment)
    func copyCells(_ attachment: TableAttachment, range: TableCellRange)
    func pasteIntoCells(_ view: TableBlockView)
    func copyTable(_ attachment: TableAttachment, asText: Bool)
    func imageAction(_ path: String, _ action: AttachmentAction)
    func openLink(_ href: String)
    func linkNotes() async -> [String]
}
