import Foundation

enum SourceEscapes {

    static func offsets(of text: String, source: String?) -> Set<Int>? {
        guard let source else { return nil }
        let raw = Array(source)
        let plain = Array(text)
        var escaped: Set<Int> = []
        var position = 0
        for (offset, character) in plain.enumerated() {
            guard position < raw.count else { return nil }
            if raw[position] == "\\", position + 1 < raw.count, raw[position + 1] == character, character.isASCII, character.isPunctuation || character.isSymbol {
                escaped.insert(offset)
                position += 2
            } else if raw[position] == character {
                position += 1
            } else {
                return nil
            }
        }
        return position == raw.count ? escaped : nil
    }
}
