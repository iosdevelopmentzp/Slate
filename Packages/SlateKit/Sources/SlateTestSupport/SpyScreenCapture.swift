import Foundation
import SlateDomain

package final class SpyScreenCapture: ScreenCapturing, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [CaptureMode] = []
    private var _producesFile = true
    private let attachments: SpyAttachmentStore

    package init(attachments: SpyAttachmentStore) {
        self.attachments = attachments
    }

    package var calls: [CaptureMode] {
        lock.withLock { _calls }
    }

    package var producesFile: Bool {
        get { lock.withLock { _producesFile } }
        set { lock.withLock { _producesFile = newValue } }
    }

    package func capture(_ mode: CaptureMode, to url: URL) async throws {
        lock.withLock { _calls.append(mode) }
        guard producesFile else { return }
        attachments.seed(url.lastPathComponent, Data([1, 2, 3]))
    }
}
