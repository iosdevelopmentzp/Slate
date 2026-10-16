import Foundation

@MainActor
final class PanelVisibility {
    var hideForCapture: () -> Void = {}
    var showAfterCapture: () -> Void = {}
}
