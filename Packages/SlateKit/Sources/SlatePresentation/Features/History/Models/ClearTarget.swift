import Foundation
import SlateDomain

enum ClearTarget: Hashable {
    case everything
    case folder(FolderPath)

    var folder: FolderPath? {
        switch self {
        case .everything: nil
        case .folder(let folder): folder
        }
    }
}
