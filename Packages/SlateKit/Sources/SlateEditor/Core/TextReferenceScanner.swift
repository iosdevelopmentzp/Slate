import Foundation

enum TextReferenceScanner {
    private static let extensions = "swift|mm|m|h|hpp|cpp|c|kts|kt|java|jsx|js|tsx|ts|py|rb|go|rs|json|yaml|yml|plist|xib|storyboard|xcstrings|strings|gradle|xml|sh|pbxproj|xcconfig|entitlements"
    private static let file = try! NSRegularExpression(pattern: #"(?<![\w/.@-])((?:[\w@+.-]+/)*[\w@+-]+(?:\.[\w-]+)*\.(?:"# + extensions + #"))(?::(\d+))?(?![\w/])"#)
    private static let ticket = try! NSRegularExpression(pattern: #"(?<![\w-])[A-Z][A-Z0-9]+-\d+(?![\w-])"#)
    private static let mergeRequest = try! NSRegularExpression(pattern: #"(?<![^\s(\[])!(\d{1,7})(?!\w)"#)
    private static let commit = try! NSRegularExpression(pattern: #"(?<![\w/.-])[0-9a-f]{7,40}(?![\w/-])(?!\.\w)"#)

    static func references(in text: String, kinds: TextReference.Kinds) -> [(range: NSRange, reference: TextReference)] {
        guard kinds.isEmpty == false else { return [] }
        let source = text as NSString
        let whole = NSRange(location: 0, length: source.length)
        let urls = BareURL.ranges(in: text)
        var found: [(range: NSRange, reference: TextReference)] = []
        func add(_ range: NSRange, _ reference: TextReference) {
            guard urls.contains(where: { NSIntersectionRange($0, range).length > 0 }) == false,
                  found.contains(where: { NSIntersectionRange($0.range, range).length > 0 }) == false else { return }
            found.append((range, reference))
        }
        if kinds.contains(.files) {
            for match in file.matches(in: text, range: whole) {
                let line = match.range(at: 2).location == NSNotFound ? nil : Int(source.substring(with: match.range(at: 2)))
                add(match.range, .file(path: source.substring(with: match.range(at: 1)), line: line))
            }
        }
        if kinds.contains(.tickets) {
            for match in ticket.matches(in: text, range: whole) {
                add(match.range, .ticket(source.substring(with: match.range)))
            }
        }
        if kinds.contains(.mergeRequests) {
            for match in mergeRequest.matches(in: text, range: whole) {
                guard let number = Int(source.substring(with: match.range(at: 1))) else { continue }
                add(match.range, .mergeRequest(number))
            }
        }
        if kinds.contains(.commits) {
            for match in commit.matches(in: text, range: whole) {
                let hash = source.substring(with: match.range)
                guard hash.contains(where: \.isNumber), hash.contains(where: \.isLetter) else { continue }
                add(match.range, .commit(hash))
            }
        }
        return found.sorted { $0.range.location < $1.range.location }
    }
}
