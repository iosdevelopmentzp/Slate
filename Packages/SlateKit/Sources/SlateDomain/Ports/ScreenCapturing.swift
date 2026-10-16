import Foundation

package protocol ScreenCapturing: Sendable {
    func capture(_ mode: CaptureMode, to url: URL) async throws
}
