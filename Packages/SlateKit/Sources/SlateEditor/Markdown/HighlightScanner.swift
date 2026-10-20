import Foundation

enum HighlightScanner {
    private struct Slot {
        let run: Int
        let offset: Int
        let character: Character
        let isMarkable: Bool
    }

    private struct Marker {
        let start: Int
        let canOpen: Bool
        let canClose: Bool
    }

    static func apply(_ runs: [InlineRun]) -> [InlineRun] {
        let slots = slots(of: runs)
        let markers = markers(in: slots)
        guard markers.count >= 2 else { return runs }
        var removed: Set<Int> = []
        var highlighted: Set<Int> = []
        var open: Marker?
        for marker in markers {
            if let opener = open, marker.canClose, marker.start > opener.start + 1 {
                removed.formUnion([opener.start, opener.start + 1, marker.start, marker.start + 1])
                highlighted.formUnion((opener.start + 2)..<marker.start)
                open = nil
            } else if open == nil, marker.canOpen {
                open = marker
            }
        }
        guard removed.isEmpty == false else { return runs }
        return rebuild(runs, slots: slots, removed: removed, highlighted: highlighted)
    }

    private static func slots(of runs: [InlineRun]) -> [Slot] {
        var slots: [Slot] = []
        for (index, run) in runs.enumerated() {
            let characters = Array(run.text)
            let wiki = wikiOffsets(in: characters)
            let scannable = run.escapes != nil && run.style.contains(.code) == false && run.style.highlight == nil && run.imagePath == nil
            for (offset, character) in characters.enumerated() {
                let markable = scannable && character == "=" && run.escapes?.contains(offset) == false && wiki.contains(offset) == false
                slots.append(Slot(run: index, offset: offset, character: character, isMarkable: markable))
            }
        }
        return slots
    }

    private static func wikiOffsets(in characters: [Character]) -> Set<Int> {
        var result: Set<Int> = []
        var index = 0
        while index + 1 < characters.count {
            guard characters[index] == "[", characters[index + 1] == "[" else {
                index += 1
                continue
            }
            var end = index + 2
            while end + 1 < characters.count, (characters[end] == "]" && characters[end + 1] == "]") == false { end += 1 }
            guard end + 1 < characters.count else { break }
            result.formUnion(index...(end + 1))
            index = end + 2
        }
        return result
    }

    private static func markers(in slots: [Slot]) -> [Marker] {
        var markers: [Marker] = []
        var index = 0
        while index < slots.count {
            guard slots[index].isMarkable else {
                index += 1
                continue
            }
            var end = index
            while end < slots.count, slots[end].isMarkable { end += 1 }
            if end - index == 2 {
                let before = index > 0 ? slots[index - 1].character : nil
                let after = end < slots.count ? slots[end].character : nil
                markers.append(Marker(start: index, canOpen: after.map(isBlank) == false, canClose: before.map(isBlank) == false))
            }
            index = end
        }
        return markers
    }

    private static func isBlank(_ character: Character) -> Bool {
        character.isWhitespace || character == RichText.lineBreak
    }

    private static func rebuild(_ runs: [InlineRun], slots: [Slot], removed: Set<Int>, highlighted: Set<Int>) -> [InlineRun] {
        var result: [InlineRun] = []
        var position = 0
        for run in runs {
            let count = run.text.count
            var pieces: [InlineRun] = []
            for offset in 0..<count {
                let slot = position + offset
                guard removed.contains(slot) == false else { continue }
                var style = run.style
                if highlighted.contains(slot), style.highlight == nil { style.highlight = .yellow }
                if let last = pieces.last, last.style == style {
                    pieces[pieces.count - 1].text.append(slots[slot].character)
                } else {
                    var piece = run
                    piece.text = String(slots[slot].character)
                    piece.style = style
                    pieces.append(piece)
                }
            }
            result.append(contentsOf: pieces)
            position += count
        }
        return result
    }
}
