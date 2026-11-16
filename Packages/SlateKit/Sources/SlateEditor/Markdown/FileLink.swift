import Foundation
import Markdown

enum FileLink {
    static let folder = "_attachments"

    static func isFile(_ destination: String) -> Bool {
        let lowered = destination.lowercased()
        if lowered.hasPrefix("file://") { return true }
        guard destination.contains(":") == false, destination.hasPrefix("/") == false, destination.hasPrefix("#") == false else { return false }
        let target = destination.split(separator: "#", maxSplits: 1).first.map(String.init) ?? destination
        let parts = target.split(separator: "/").map(String.init)
        guard parts.count >= 2, let name = parts.last, name.isEmpty == false else { return false }
        return parts.dropLast().contains(folder)
    }

    static func block(_ link: Link) -> ReadBlock? {
        guard link.title == nil, let destination = link.destination, isFile(destination),
              link.children.allSatisfy({ $0 is Text }) else { return nil }
        let name = link.plainText
        guard name.isEmpty == false, name.contains(RichText.lineBreak) == false else { return nil }
        let block = BlockAttributes(kind: .file, filePath: destination, fileName: name)
        return ReadBlock(text: NSAttributedString(string: RichText.attachmentString), attributes: block)
    }

    static func markdown(_ block: BlockAttributes) -> String? {
        guard let path = block.filePath, path.isEmpty == false else { return nil }
        let name = block.fileName.flatMap { $0.isEmpty ? nil : $0 } ?? (path as NSString).lastPathComponent
        return InlineWriter.lines(of: NSAttributedString(string: name, attributes: [.slateHref: path])).joined(separator: "\n")
    }
}
