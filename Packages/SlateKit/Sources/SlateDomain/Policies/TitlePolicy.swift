import Foundation

package enum TitlePolicy {

    package static func title(fromBody body: String) -> String? {
        for line in body.split(separator: "\n") {
            let text = PreviewPolicy.plainText(of: line.trimmingCharacters(in: .whitespaces))
            guard text.isEmpty == false else { continue }
            return String(text.prefix(StemPolicy.maxLength)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
}
