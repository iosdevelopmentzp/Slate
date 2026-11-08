import Foundation

nonisolated enum DiagramDrawing: Equatable {
    case size(CGSize)
    case error(String)

    static let unknownError = "The diagram could not be drawn."

    static func parse(_ value: Any?) -> DiagramDrawing {
        guard let values = value as? [String: Any] else { return .error(unknownError) }
        if let message = values["error"] as? String {
            return .error(message.isEmpty ? unknownError : message)
        }
        let width = (values["width"] as? NSNumber)?.doubleValue ?? 0
        let height = (values["height"] as? NSNumber)?.doubleValue ?? 0
        guard width > 0, height > 0 else { return .error(unknownError) }
        return .size(CGSize(width: width, height: height))
    }
}
