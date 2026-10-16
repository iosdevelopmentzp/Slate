import Foundation

package struct DoctorCheck: Identifiable, Hashable, Sendable {
    package let id: String
    package let title: String
    package let isOK: Bool
    package let detail: String

    package init(id: String, title: String, isOK: Bool, detail: String) {
        self.id = id
        self.title = title
        self.isOK = isOK
        self.detail = detail
    }
}
