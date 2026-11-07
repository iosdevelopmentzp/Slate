import Foundation

enum CalloutReader {
    private static let marker = try! NSRegularExpression(pattern: #"^\[!([A-Za-z][A-Za-z0-9_-]*)\]([+-]?)"#)

    static func read(_ blocks: [ReadBlock]) -> [ReadBlock] {
        guard let first = blocks.first, let found = marker.firstMatch(in: first.text.string, range: NSRange(location: 0, length: first.text.length)) else { return blocks }
        let source = first.text.string as NSString
        let name = source.substring(with: found.range(at: 1)) + source.substring(with: found.range(at: 2))
        var start = NSMaxRange(found.range)
        while start < source.length, source.character(at: start) == 0x20 { start += 1 }
        let lineBreak = source.range(of: RichText.lineBreakString, range: NSRange(location: start, length: source.length - start))
        let titleEnd = lineBreak.location == NSNotFound ? source.length : lineBreak.location
        let title = first.text.attributedSubstring(from: NSRange(location: start, length: titleEnd - start))
        var header = first.attributes
        header.callout = name
        header.isCalloutHeader = true
        var body = first.attributes
        body.callout = name
        var result = [ReadBlock(text: title, attributes: header)]
        if lineBreak.location != NSNotFound {
            let bodyStart = NSMaxRange(lineBreak)
            result.append(ReadBlock(text: first.text.attributedSubstring(from: NSRange(location: bodyStart, length: source.length - bodyStart)), attributes: body))
        }
        result += blocks.dropFirst().map { ReadBlock(text: $0.text, attributes: body) }
        return result
    }
}
