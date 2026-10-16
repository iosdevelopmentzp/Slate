import Foundation
import SlateDomain

struct MockScreenCapture: ScreenCapturing {
    func capture(_ mode: CaptureMode, to url: URL) async throws {}
}
