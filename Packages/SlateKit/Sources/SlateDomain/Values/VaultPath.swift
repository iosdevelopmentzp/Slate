import Foundation

package struct VaultPath: Hashable, Sendable, Codable {
    package static let noteExtension = "md"

    package let rawValue: String

    package init(rawValue: String) {
        self.rawValue = rawValue
    }

    package init(space: SpaceName, stem: String) {
        rawValue = "\(space.rawValue)/\(stem).\(Self.noteExtension)"
    }

    package init(folder: FolderPath, stem: String) {
        rawValue = "\(folder.rawValue)/\(stem).\(Self.noteExtension)"
    }

    package var folderPath: FolderPath? {
        guard space != nil else { return nil }
        return FolderPath(rawValue: folder)
    }

    package var components: [String] {
        rawValue.split(separator: "/").map(String.init)
    }

    package var space: SpaceName? {
        guard components.count > 1, let first = components.first, first.hasPrefix(".") == false, first.hasPrefix("_") == false else { return nil }
        return SpaceName(rawValue: first)
    }

    package var fileName: String {
        components.last ?? rawValue
    }

    package var stem: String {
        let suffix = ".\(Self.noteExtension)"
        guard fileName.hasSuffix(suffix) else { return fileName }
        return String(fileName.dropLast(suffix.count))
    }

    package var folder: String {
        components.dropLast().joined(separator: "/")
    }

    package var depth: Int {
        components.count - 1
    }

    package var subfolder: String? {
        guard depth > 1 else { return nil }
        return components.dropFirst().dropLast().joined(separator: "/")
    }

    package var isNote: Bool {
        fileName.hasSuffix(".\(Self.noteExtension)") && space != nil
    }

    package func replacingStem(with stem: String) -> VaultPath {
        let name = "\(stem).\(Self.noteExtension)"
        return VaultPath(rawValue: folder.isEmpty ? name : "\(folder)/\(name)")
    }
}
