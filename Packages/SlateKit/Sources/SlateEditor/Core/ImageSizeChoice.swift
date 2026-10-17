import Foundation

final class ImageSizeChoice: NSObject {
    let location: Int
    let cell: TableCellIndex?
    let width: Int?

    init(location: Int, cell: TableCellIndex? = nil, width: Int?) {
        self.location = location
        self.cell = cell
        self.width = width
    }
}
