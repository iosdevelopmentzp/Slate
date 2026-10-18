import Foundation

package enum LineDiffPolicy {
    package static func lines(from old: String, to new: String) -> [DiffLine] {
        let before = split(old)
        let after = split(new)
        let difference = after.difference(from: before)
        var removed = Set<Int>()
        var inserted = Set<Int>()
        for change in difference {
            switch change {
            case .remove(let offset, _, _): removed.insert(offset)
            case .insert(let offset, _, _): inserted.insert(offset)
            }
        }
        var result: [DiffLine] = []
        var oldIndex = 0
        var newIndex = 0
        while oldIndex < before.count || newIndex < after.count {
            if oldIndex < before.count, removed.contains(oldIndex) {
                result.append(DiffLine(.removed, before[oldIndex]))
                oldIndex += 1
            } else if newIndex < after.count, inserted.contains(newIndex) {
                result.append(DiffLine(.added, after[newIndex]))
                newIndex += 1
            } else {
                if oldIndex < before.count {
                    result.append(DiffLine(.same, before[oldIndex]))
                }
                oldIndex += 1
                newIndex += 1
            }
        }
        return result
    }

    package static func counts(_ lines: [DiffLine]) -> (added: Int, removed: Int) {
        (lines.filter { $0.kind == .added }.count, lines.filter { $0.kind == .removed }.count)
    }

    private static func split(_ text: String) -> [String] {
        guard text.isEmpty == false else { return [] }
        var lines = text.components(separatedBy: "\n")
        if lines.last == "" { lines.removeLast() }
        return lines
    }
}
