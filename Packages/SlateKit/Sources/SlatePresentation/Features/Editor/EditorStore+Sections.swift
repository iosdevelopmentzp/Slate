import Foundation
import SlateDomain

extension EditorStore {
    var collapsedSections: [String] {
        sectionFolds.sections(for: document?.id)
    }

    func setCollapsedSections(_ sections: [String]) {
        sectionFolds.set(sections, for: document?.id)
    }
}
