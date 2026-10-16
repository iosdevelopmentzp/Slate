import AppKit
import SwiftUI

package enum Theme {
    package static let base = Color(nsColor: .windowBackgroundColor)
    package static let surface = Color(nsColor: .controlBackgroundColor)
    package static let border = Color(nsColor: .separatorColor)
    package static let text = Color(nsColor: .labelColor)
    package static let secondaryText = Color(nsColor: .secondaryLabelColor)
    package static let selection = Color.accentColor
    package static let codeBackground = Color(nsColor: .quaternaryLabelColor).opacity(0.3)
    package static let hover = Color.primary.opacity(0.05)
    package static let shadow = Color.black.opacity(0.08)
    package static let scrim = Color.black.opacity(0.12)
}
