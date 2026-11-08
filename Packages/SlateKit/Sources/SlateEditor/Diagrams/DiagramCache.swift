import AppKit

final class DiagramCache {
    static let limit = 64

    var render: (String, Bool) async -> DiagramPicture
    var pictures: [DiagramKey: DiagramPicture] = [:]
    var task: Task<Void, Never>?
    var needsAnotherPass = false
    var openParagraph: Int?

    init(render: ((String, Bool) async -> DiagramPicture)? = nil) {
        if let render {
            self.render = render
        } else {
            let renderer = MermaidRenderer()
            self.render = { source, dark in await renderer.render(source, dark: dark) }
        }
    }

    func store(_ picture: DiagramPicture, for key: DiagramKey) {
        if pictures.count >= Self.limit { pictures.removeAll() }
        pictures[key] = picture
    }
}
