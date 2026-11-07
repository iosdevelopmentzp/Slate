import Foundation

enum XcodeLog {
    private static let prefixes = [
        try! NSRegularExpression(pattern: #"^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}[.:]\d+(?:[+-]\d{2}:?\d{2}|Z)? +[^\[\s]+\[\d+:[0-9a-fx]+\] +"#),
        try! NSRegularExpression(pattern: #"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+[+-]\d{4} +0x[0-9a-f]+ +\w+ +0x[0-9a-f]+ +\d+ +\d+ +[^:]+: +"#),
    ]

    static func cleaned(_ text: String) -> String? {
        let lines = text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        var stripped = 0
        let result = lines.map { line -> String in
            let range = NSRange(location: 0, length: (line as NSString).length)
            for prefix in prefixes {
                if let match = prefix.firstMatch(in: line, range: range) {
                    stripped += 1
                    return (line as NSString).substring(from: NSMaxRange(match.range))
                }
            }
            return line
        }
        let filled = lines.filter { $0.trimmingCharacters(in: .whitespaces).isEmpty == false }.count
        guard stripped > 0, stripped * 2 >= filled else { return nil }
        return result.joined(separator: "\n")
    }
}
