import Foundation

nonisolated package struct TableBlock: Hashable, Sendable {
    package var model: TableModel
    package var source: String?

    package init(model: TableModel, source: String? = nil) {
        self.model = model
        self.source = source
    }

    var markdown: String {
        if let source, TableMarkdown.parse(source) == model { return source }
        return TableMarkdown.render(model)
    }
}
