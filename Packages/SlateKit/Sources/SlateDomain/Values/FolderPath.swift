import Foundation

package struct FolderPath: Hashable, Sendable, Codable {
    package let rawValue: String

    package init(rawValue: String) {
        self.rawValue = rawValue
    }

    package init(space: SpaceName) {
        rawValue = space.rawValue
    }

    package var components: [String] {
        rawValue.split(separator: "/").map(String.init)
    }

    package var space: SpaceName {
        SpaceName(rawValue: components.first ?? rawValue)
    }

    package var name: String {
        components.last ?? rawValue
    }

    package var depth: Int {
        components.count
    }

    package var isSpace: Bool {
        depth == 1
    }

    package var parent: FolderPath? {
        guard depth > 1 else { return nil }
        return FolderPath(rawValue: components.dropLast().joined(separator: "/"))
    }

    package func appending(_ name: String) -> FolderPath {
        FolderPath(rawValue: "\(rawValue)/\(name)")
    }

    package func contains(_ path: VaultPath) -> Bool {
        path.rawValue.hasPrefix(rawValue + "/")
    }

    package func contains(_ folder: FolderPath) -> Bool {
        folder.rawValue.hasPrefix(rawValue + "/")
    }

    package func moved(from old: FolderPath, to new: FolderPath) -> FolderPath {
        if self == old { return new }
        guard old.contains(self) else { return self }
        return FolderPath(rawValue: new.rawValue + rawValue.dropFirst(old.rawValue.count))
    }
}
