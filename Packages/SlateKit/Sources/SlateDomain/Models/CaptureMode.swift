import Foundation

package enum CaptureMode: String, Hashable, Sendable {
    case region
    case window
    case simulator

    package var source: String {
        switch self {
        case .region: "screenshot"
        case .window: "window"
        case .simulator: "simulator"
        }
    }
}
