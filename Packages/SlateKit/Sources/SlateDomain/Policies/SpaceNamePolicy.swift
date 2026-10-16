import Foundation

package enum SpaceNamePolicy {

    package static func validated(_ name: String) -> SpaceName? {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return nil }
        let stem = StemPolicy.stem(forTitle: name)
        guard stem.hasPrefix("_") == false else { return nil }
        return SpaceName(rawValue: stem)
    }
}
