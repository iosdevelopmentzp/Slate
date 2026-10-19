import AppKit

struct TableGrab: Equatable {
    var grip: TableGrip
    var start: CGPoint
    var target: Int?
    var isDragging = false
}
