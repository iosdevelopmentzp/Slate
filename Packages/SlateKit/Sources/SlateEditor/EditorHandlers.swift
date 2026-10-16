import Foundation

package struct EditorHandlers {
    package var didEndEditing: () -> Void

    package init(didEndEditing: @escaping () -> Void = {}) {
        self.didEndEditing = didEndEditing
    }
}
