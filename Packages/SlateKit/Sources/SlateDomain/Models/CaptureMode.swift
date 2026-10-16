import Foundation

package enum CaptureMode: String, Hashable, Sendable {
    case region
    case window

    package var source: String {
        switch self {
        case .region: "screenshot"
        case .window: "window"
        }
    }
}
