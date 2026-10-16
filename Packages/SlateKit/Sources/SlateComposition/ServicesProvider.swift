import AppKit
import Foundation

@MainActor
final class ServicesProvider: NSObject {
    private let onText: (String) -> Void

    init(onText: @escaping (String) -> Void) {
        self.onText = onText
    }

    @objc func addToSlate(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let text = pasteboard.string(forType: .string), text.isEmpty == false else {
            error.pointee = "No text was selected." as NSString
            return
        }
        onText(text)
    }
}
