import AppKit

extension RichTextController {
    static let diagramDelay: Duration = .milliseconds(400)

    var isDarkAppearance: Bool {
        textView.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }

    func diagramPicture(for source: String) -> DiagramPicture? {
        if let picture = diagrams.pictures[DiagramKey(source: source, dark: isDarkAppearance)] { return picture }
        scheduleDiagrams()
        return nil
    }

    func showsDiagramCode(at paragraph: Int) -> Bool {
        diagrams.openParagraph == paragraph
    }

    func updateOpenDiagram(focused: Bool? = nil) {
        let isFocused = focused ?? (textView.window?.firstResponder === textView)
        let open = isFocused ? diagramParagraph(at: textView.selectedRange().location) : nil
        guard open != diagrams.openParagraph else { return }
        let previous = diagrams.openParagraph
        diagrams.openParagraph = open
        restyleParagraphs(at: [previous, open].compactMap { $0 })
    }

    func diagramsChangedLook() {
        restyleParagraphs(at: diagramParagraphs().map(\.location))
    }

    func diagramParagraphs() -> [NSRange] {
        var paragraphs: [NSRange] = []
        storage.enumerateAttribute(.slateLanguage, in: NSRange(location: 0, length: storage.length)) { value, range, _ in
            guard let language = value as? String, language.lowercased() == DiagramSource.fence else { return }
            var location = range.location
            while location < NSMaxRange(range) {
                let paragraph = paragraphRange(at: location)
                if DiagramSource.isDiagram(block(at: paragraph.location)), paragraphs.last != paragraph { paragraphs.append(paragraph) }
                location = NSMaxRange(paragraph)
            }
        }
        return paragraphs
    }

    private func diagramParagraph(at location: Int) -> Int? {
        guard storage.length > 0 else { return nil }
        let paragraph = paragraphRange(at: min(location, storage.length - 1))
        guard location <= NSMaxRange(contentRange(of: paragraph)), DiagramSource.isDiagram(block(at: paragraph.location)) else { return nil }
        return paragraph.location
    }

    private func diagramSource(of paragraph: NSRange) -> String {
        DiagramSource.text(of: string.substring(with: contentRange(of: paragraph)))
    }

    private func scheduleDiagrams() {
        guard diagrams.task == nil else {
            diagrams.needsAnotherPass = true
            return
        }
        diagrams.task = Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.diagramDelay)
            guard let self else { return }
            await renderMissingDiagrams()
        }
    }

    private func renderMissingDiagrams() async {
        repeat {
            diagrams.needsAnotherPass = false
            let dark = isDarkAppearance
            let sources = Set(diagramParagraphs().map(diagramSource(of:)))
            for source in sources where diagrams.pictures[DiagramKey(source: source, dark: dark)] == nil {
                let picture = await diagrams.render(source, dark)
                diagrams.store(picture, for: DiagramKey(source: source, dark: dark))
                restyleParagraphs(at: diagramParagraphs().filter { diagramSource(of: $0) == source }.map(\.location))
            }
            if diagrams.needsAnotherPass { try? await Task.sleep(for: Self.diagramDelay) }
        } while diagrams.needsAnotherPass
        diagrams.task = nil
    }
}
