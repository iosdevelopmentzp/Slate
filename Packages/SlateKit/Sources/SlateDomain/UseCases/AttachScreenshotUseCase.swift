import Foundation

package struct AttachScreenshotUseCase: Sendable {
    let capture: any ScreenCapturing
    let attachments: any AttachmentStore
    let clock: any Clock

    package func execute(_ mode: CaptureMode, for note: VaultPath) async throws -> String? {
        let base = AttachmentPolicy.fileName(source: mode.source, fileExtension: "png", date: clock.now(), timeZone: clock.timeZone)
        let name = AttachmentPolicy.unique(base, among: try await attachments.fileNames())
        try await capture.capture(mode, to: attachments.url(for: name))
        guard let size = await attachments.size(of: name), size > 0 else { return nil }
        return AttachmentPolicy.markdown(file: name, from: note)
    }
}
