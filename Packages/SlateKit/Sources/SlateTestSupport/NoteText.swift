import Foundation
import SlateDomain

package enum NoteText {

    package static func make(id: String? = nil, title: String, type: String? = nil, pinned: Bool? = nil, status: String? = nil, body: String) -> String {
        let header = NoteHeader(id: id.map(NoteID.init(rawValue:)), title: title, type: type, pinned: pinned, status: status)
        return String(decoding: NoteCodec.encode(header: header, body: body, opaqueHeader: nil, timeZone: .gmt), as: UTF8.self)
    }
}
