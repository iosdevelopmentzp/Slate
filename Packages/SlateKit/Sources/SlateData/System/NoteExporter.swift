import AppKit
import SlateDomain

struct NoteExporter: NoteExporting {
    let formatter = HTMLExporter()
    var downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())

    func html(title: String, body: String, folder: URL?) -> String {
        formatter.html(title: title, body: body, folder: folder)
    }

    func pdf(title: String, body: String, folder: URL?) async throws -> Data {
        let page = html(title: title, body: body, folder: folder)
        return try await MainActor.run {
            guard let data = page.data(using: .utf8),
                  let imported = NSAttributedString(html: data, options: [.characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
            let attributed = Self.spacingCodeBlocks(imported)
            let printInfo = NSPrintInfo()
            printInfo.topMargin = 48
            printInfo.bottomMargin = 48
            printInfo.leftMargin = 48
            printInfo.rightMargin = 48
            printInfo.horizontalPagination = .fit
            printInfo.verticalPagination = .automatic
            printInfo.isVerticallyCentered = false
            printInfo.isHorizontallyCentered = false
            let width = printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin
            let view = NSTextView(usingTextLayoutManager: false)
            view.frame = NSRect(x: 0, y: 0, width: width, height: printInfo.paperSize.height)
            view.maxSize = NSSize(width: width, height: .greatestFiniteMagnitude)
            view.isVerticallyResizable = true
            view.textContainer?.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)
            view.textContainer?.widthTracksTextView = true
            view.textStorage?.setAttributedString(attributed)
            if let container = view.textContainer {
                view.layoutManager?.ensureLayout(for: container)
            }
            view.sizeToFit()
            let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
            defer { try? FileManager.default.removeItem(at: file) }
            printInfo.jobDisposition = .save
            printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = file
            let operation = NSPrintOperation(view: view, printInfo: printInfo)
            operation.showsPrintPanel = false
            operation.showsProgressPanel = false
            guard operation.run() else { throw CocoaError(.fileWriteUnknown) }
            return try Data(contentsOf: file)
        }
    }

    @MainActor
    static func spacingCodeBlocks(_ text: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: text)
        let string = result.string as NSString
        var paragraphs: [(range: NSRange, isCode: Bool)] = []
        var location = 0
        while location < string.length {
            let range = string.paragraphRange(for: NSRange(location: location, length: 0))
            var isCode = range.length > 1
            result.enumerateAttribute(.font, in: NSRange(location: range.location, length: max(range.length - 1, 0))) { value, _, stop in
                if (value as? NSFont)?.isFixedPitch != true {
                    isCode = false
                    stop.pointee = true
                }
            }
            paragraphs.append((range, isCode))
            location = NSMaxRange(range)
        }
        for (index, paragraph) in paragraphs.enumerated() where paragraph.isCode {
            let style = (result.attribute(.paragraphStyle, at: paragraph.range.location, effectiveRange: nil) as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            style.firstLineHeadIndent = 8
            style.headIndent = 8
            if index == 0 || paragraphs[index - 1].isCode == false { style.paragraphSpacingBefore = 12 }
            if index == paragraphs.count - 1 || paragraphs[index + 1].isCode == false { style.paragraphSpacing = 12 }
            result.addAttribute(.paragraphStyle, value: style, range: paragraph.range)
        }
        return result
    }

    func saveToDownloads(_ data: Data, fileName: String) async throws -> URL {
        let url = freeURL(for: fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    func copyToDownloads(_ source: URL) async throws -> URL {
        let url = freeURL(for: source.lastPathComponent)
        try FileManager.default.copyItem(at: source, to: url)
        return url
    }

    func temporaryFile(_ data: Data, fileName: String) async throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Slate versions", isDirectory: true).appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent(FileNamePolicy.cleaned(fileName) ?? "version")
        try data.write(to: url, options: .atomic)
        return url
    }

    private func freeURL(for fileName: String) -> URL {
        let cleaned = fileName.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        let base = (cleaned as NSString).deletingPathExtension
        let ext = (cleaned as NSString).pathExtension
        var url = downloads.appendingPathComponent(cleaned)
        var number = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = downloads.appendingPathComponent(ext.isEmpty ? "\(base) \(number)" : "\(base) \(number).\(ext)")
            number += 1
        }
        return url
    }
}
